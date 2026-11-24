//----------------------------------------------------------------------------
// ddh_overlay.cpp -- in-game overlay drawn on top of the game frame.
//
// MILESTONE S1 (this file, now verifiable):
//   * patch the *present* call of the running game and draw with that same GL
//     context right before the buffer swap;
//   * draw one 30x30 square button in the top-right corner (dark + gold frame)
//     plus, when toggled, a panel area; both are plain colour for now;
//   * hit-test the button so ddh.cpp can turn a left click into a toggle.
//
// Present call facts for War3 1.27 in OpenGL mode (verified by dumping the
// imports of game.dll): game.dll imports OPENGL32.dll!wglSwapLayerBuffers,
// wglMakeCurrent, wglCreateContext, wglGetProcAddress -- it does NOT import
// gdi32!SwapBuffers nor opengl32!wglSwapBuffers. Hooking only wglSwapBuffers
// therefore never fires; that was the reason S1 showed nothing. All three are
// patched here, in every loaded module's IAT, and re-patched for a while
// because game.dll is loaded after ddh.dll.
//
// NOTE: d3d8proxy/d3d9/DXVK are NOT in this path; the launcher runs the game
// with the OpenGL renderer (EverConfig LaunchRenderingEngine=OpenGL).
//
// MILESTONE S2 (next): the panel area takes a WebView2 frame bitmap that a
// helper process publishes through shared memory; the upload path is already
// stubbed (OvUploadFrame + panel quad).
//----------------------------------------------------------------------------
#include <windows.h>
#include <tlhelp32.h>
#include <shellapi.h>
#include <shlobj.h>
#include <GL/gl.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdarg.h>

#ifndef GL_BGRA
#define GL_BGRA 0x80E1
#endif
#ifndef GL_DRAW_FRAMEBUFFER
#define GL_DRAW_FRAMEBUFFER         0x8CA9
#define GL_READ_FRAMEBUFFER         0x8CAA
#define GL_DRAW_FRAMEBUFFER_BINDING 0x8CA6
#define GL_READ_FRAMEBUFFER_BINDING 0x8CA8
#endif
#ifndef GL_FUNC_ADD
#define GL_FUNC_ADD 0x8006
#endif

/* ---- fixed debug log -------------------------------------------------------
   The game process may have a different %TEMP% (and may run elevated), so the
   log lives at a fixed, always-writable path. %TEMP% is only a last resort. */
#define OV_SHARED_DIR   "C:\\Users\\Public\\Documents\\War3DeathSettlement"
#define OV_LOG_DIR      OV_SHARED_DIR
#define OV_LOG_FILE     OV_SHARED_DIR "\\ddh-overlay.txt"

/* ---- geometry ------------------------------------------------------------- */
#define OV_BTN_W        30   /* KK-like square icon, px */
#define OV_BTN_H        30
#define OV_BTN_MARGIN_R 40   /* right margin from the right edge */
#define OV_BTN_MARGIN_T 26   /* top margin from the top edge */
#define OV_BTN_STATE_FILE OV_SHARED_DIR "\\ddh-button-seq.txt"

/* ---- panel (placeholder; WebView2 frame lands here later) ----------------- */
#define OV_PANEL_W      1200
#define OV_PANEL_H      760
#define OV_PANEL_GAP    8

typedef BOOL(WINAPI* fn_swap_t)(HDC);
typedef BOOL(WINAPI* fn_swaplayer_t)(HDC, UINT);
typedef BOOL(__fastcall* fn_cursor_layer_update_t)(void*, int, int, int, int);

static fn_swap_t        g_ovOrigSwap = NULL;      /* gdi32!SwapBuffers            */
static fn_swap_t        g_ovOrigWglSwap = NULL;   /* opengl32!wglSwapBuffers      */
static fn_swaplayer_t   g_ovOrigWglLayers = NULL; /* opengl32!wglSwapLayerBuffers */
static fn_cursor_layer_update_t g_ovOrigCursorLayerUpdate = NULL;

static volatile LONG g_ovInited = 0;
static volatile LONG g_ovFrames = 0;
static volatile LONG g_ovLogCount = 0;
static volatile LONG g_ovProven = 0;       /* 1 = our pixels really reach the frame */
static volatile LONG g_ovBtnVisible = 1;   /* the 30x30 icon is always drawn   */
static volatile LONG g_ovPanelVisible = 0; /* HTML panel, toggled by the click */
static GLuint        g_ovTex = 0;
static HGLRC         g_ovCtx = NULL;
static RECT          g_ovRect = { 0, 0, 0, 0 };   /* button rect, client px */
static RECT          g_ovPanelRect = { 0, 0, 0, 0 };
static HWND          g_ovWnd = NULL;
static volatile LONG g_ovMouseDown = 0;
static volatile LONG g_ovLastToggle = 0;
static int           g_ovPatchPass = 0;
static int           g_ovTestFill = 0;    /* DDH_OVERLAY_TESTFILL=1: paint the whole screen */
static int           g_ovProbeMode = 0;   /* DDH_OVERLAY_PROBE=1: A/B test the paint paths */
static int           g_ovDrawCursor = 0;
static int           g_ovUseGl = 0;
static int           g_ovForceOsCursor = 0;   /* KK-style: leave the system cursor alone */      /* 0 = window-only overlay: never touch GL state */  /* 1 = paint our own arrow (the OS cursor is used by default) */
static volatile LONG g_ovCursorHookDone = 0;  /* 0=not tried, 1=installed, 2=failed */
static volatile LONG g_ovGameLayerFrames = 0;
static INIT_ONCE     g_ovButtonMarkerOnce = INIT_ONCE_STATIC_INIT;
static char          g_ovButtonMarker[2] = { 'D', '\0' };

static void OvDraw(HDC hdc);

static int OvUseGameLayer(void)
{
    return g_ovUseGl && InterlockedCompareExchange(&g_ovCursorHookDone, 0, 0) == 1;
}

/* ------------------------------------------------------------------ logging */
static void OvLogV(const char* fmt, va_list ap)
{
    char path[MAX_PATH];
    char line[1024];
    int n = _snprintf_s(line, sizeof(line), _TRUNCATE, "[%lu] ",
                        (unsigned long)GetCurrentProcessId());
    if (n < 0) n = 0;
    int m = _vsnprintf_s(line + n, sizeof(line) - n, _TRUNCATE, fmt, ap);
    if (m < 0) m = 0;
    n += m;
    if (n < (int)sizeof(line) - 2) { line[n++] = '\r'; line[n++] = '\n'; }

    CreateDirectoryA(OV_SHARED_DIR, NULL);

    /* shared path first; fall back only if it is really not writable */
    const char* cands[3] = { OV_LOG_FILE, NULL, NULL };
    char alt1[MAX_PATH] = { 0 };
    char alt2[MAX_PATH] = { 0 };
    {
        char base[MAX_PATH] = { 0 };
        if (GetEnvironmentVariableA("LOCALAPPDATA", base, MAX_PATH) > 0)
        {
            char dir[MAX_PATH] = { 0 };
            _snprintf_s(dir, sizeof(dir), _TRUNCATE, "%s\\War3DeathSettlement", base);
            CreateDirectoryA(dir, NULL);
            _snprintf_s(alt1, sizeof(alt1), _TRUNCATE, "%s\\ddh-overlay.txt", dir);
            cands[1] = alt1;
        }
        char tmp[MAX_PATH] = { 0 };
        if (GetTempPathA(sizeof(tmp), tmp) > 0)
        {
            _snprintf_s(alt2, sizeof(alt2), _TRUNCATE, "%sddh-overlay.txt", tmp);
            cands[2] = alt2;
        }
    }
    for (int i = 0; i < 3; ++i)
    {
        if (!cands[i]) continue;
        strncpy_s(path, sizeof(path), cands[i], _TRUNCATE);
        /* share read/write so an external tool can tail the log while playing */
        HANDLE h = CreateFileA(path, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE,
                               NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
        if (h == INVALID_HANDLE_VALUE) continue;
        DWORD w = 0;
        WriteFile(h, line, (DWORD)n, &w, NULL);
        CloseHandle(h);
        return;
    }
}

static void OvLog(const char* fmt, ...)
{
    va_list ap; va_start(ap, fmt);
    OvLogV(fmt, ap);
    va_end(ap);
}

/*
 * Every injected core gets the next visible marker: A..S, then A again.
 * The tiny state file is locked so two games starting together cannot both
 * read the same value. The marker is only presentation and never affects
 * settlement behaviour.
 */
static BOOL CALLBACK OvInitButtonMarker(PINIT_ONCE, PVOID, PVOID*)
{
    CreateDirectoryA(OV_SHARED_DIR, NULL);
    HANDLE file = CreateFileA(OV_BTN_STATE_FILE, GENERIC_READ | GENERIC_WRITE,
                              FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_ALWAYS,
                              FILE_ATTRIBUTE_NORMAL, NULL);
    char previous = 0;
    DWORD read = 0;
    int locked = 0;
    if (file != INVALID_HANDLE_VALUE)
    {
        OVERLAPPED lock = { 0 };
        locked = LockFileEx(file, LOCKFILE_EXCLUSIVE_LOCK, 0, MAXDWORD, MAXDWORD,
                            &lock) ? 1 : 0;
        SetFilePointer(file, 0, NULL, FILE_BEGIN);
        ReadFile(file, &previous, 1, &read, NULL);
    }

    char next;
    if (read == 1 && previous >= 'A' && previous <= 'S')
        next = previous == 'S' ? 'A' : (char)(previous + 1);
    else
        next = 'D';
    g_ovButtonMarker[0] = next;

    if (file != INVALID_HANDLE_VALUE)
    {
        DWORD written = 0;
        SetFilePointer(file, 0, NULL, FILE_BEGIN);
        WriteFile(file, &next, 1, &written, NULL);
        SetEndOfFile(file);
        if (locked)
        {
            OVERLAPPED unlock = { 0 };
            UnlockFileEx(file, 0, MAXDWORD, MAXDWORD, &unlock);
        }
        CloseHandle(file);
    }
    else
    {
        OvLog("button marker state open failed err=%lu; using D", GetLastError());
    }
    OvLog("button marker=%c previous=%c state=%s", next,
          read == 1 ? previous : '?', OV_BTN_STATE_FILE);
    return TRUE;
}

extern "C" const char* DdhOverlayMarkerText(void)
{
    InitOnceExecuteOnce(&g_ovButtonMarkerOnce, OvInitButtonMarker, NULL, NULL);
    return g_ovButtonMarker;
}

/* ddh.cpp owns DdhOverlayLog (it routes into the main ddh log); the overlay
   uses OvLog so its diagnostics survive even when the main log switch is off. */

/* --------------------------------------------------------------- env flags */
static int OvEnvOn(const char* name, int dflt)
{
    char v[16] = { 0 };
    DWORD n = GetEnvironmentVariableA(name, v, sizeof(v));
    if (n == 0 || n >= sizeof(v)) return dflt;
    if (!_stricmp(v, "0") || !_stricmp(v, "false") || !_stricmp(v, "off")) return 0;
    if (!_stricmp(v, "1") || !_stricmp(v, "true") || !_stricmp(v, "on")) return 1;
    return dflt;
}

/* -------------------------------------------------------------- IAT patcher */
static int OvPatchIat(HMODULE mod, const char* dllA, const char* fn,
                      void* hook, void** orig, const char* modName)
{
    if (!mod) return 0;
    IMAGE_DOS_HEADER* dos = (IMAGE_DOS_HEADER*)mod;
    if (dos->e_magic != IMAGE_DOS_SIGNATURE) return 0;
    IMAGE_NT_HEADERS* nt = (IMAGE_NT_HEADERS*)((BYTE*)mod + dos->e_lfanew);
    if (nt->Signature != IMAGE_NT_SIGNATURE) return 0;
    IMAGE_DATA_DIRECTORY* dir = &nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
    if (!dir->VirtualAddress) return 0;

    IMAGE_IMPORT_DESCRIPTOR* imp = (IMAGE_IMPORT_DESCRIPTOR*)((BYTE*)mod + dir->VirtualAddress);
    int patched = 0;
    for (; imp->Name; ++imp)
    {
        const char* dll = (const char*)((BYTE*)mod + imp->Name);
        if (_stricmp(dll, dllA) != 0) continue;
        IMAGE_THUNK_DATA* thunk = (IMAGE_THUNK_DATA*)((BYTE*)mod + imp->FirstThunk);
        IMAGE_THUNK_DATA* nth = imp->OriginalFirstThunk
            ? (IMAGE_THUNK_DATA*)((BYTE*)mod + imp->OriginalFirstThunk) : thunk;
        for (; thunk->u1.Function; ++thunk, ++nth)
        {
            if (!nth->u1.AddressOfData || (nth->u1.Ordinal & IMAGE_ORDINAL_FLAG)) continue;
            IMAGE_IMPORT_BY_NAME* ibn = (IMAGE_IMPORT_BY_NAME*)((BYTE*)mod + nth->u1.AddressOfData);
            if (_stricmp((const char*)ibn->Name, fn) != 0) continue;

            /* already ours: do not overwrite the saved original with our hook */
            if ((void*)thunk->u1.Function == hook) { ++patched; continue; }

            DWORD oldProt = 0;
            if (!VirtualProtect(&thunk->u1.Function, sizeof(void*), PAGE_READWRITE, &oldProt)) continue;
            if (orig && !*orig) *orig = (void*)thunk->u1.Function;
            thunk->u1.Function = (ULONG_PTR)hook;
            DWORD tmp = 0;
            VirtualProtect(&thunk->u1.Function, sizeof(void*), oldProt, &tmp);
            ++patched;
        }
    }
    if (patched)
        OvLog("patch %s!%s in %s: %d entr%s", dllA, fn, modName ? modName : "?",
              patched, patched == 1 ? "y" : "ies");
    return patched;
}

static void OvPatchAll(const char* dll, const char* fn, void* hook, void** orig)
{
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32,
                                           GetCurrentProcessId());
    if (snap == INVALID_HANDLE_VALUE) return;
    MODULEENTRY32W me;
    me.dwSize = sizeof(me);
    if (Module32FirstW(snap, &me))
    {
        do
        {
            char name[MAX_PATH] = { 0 };
            WideCharToMultiByte(CP_ACP, 0, me.szModule, -1, name, sizeof(name) - 1, NULL, NULL);
            OvPatchIat((HMODULE)me.modBaseAddr, dll, fn, hook, orig, name);
        } while (Module32NextW(snap, &me));
    }
    CloseHandle(snap);
}

/* ----------------------------------------------------------------- helpers */
static HWND OvGameWindow(HDC hdc)
{
    if (g_ovWnd && IsWindow(g_ovWnd)) return g_ovWnd;
    HWND w = hdc ? WindowFromDC(hdc) : NULL;
    if (!w) w = GetForegroundWindow();
    g_ovWnd = w;
    return w;
}

/* a KK-like button: dark plate, gold edge, and (for now) a plain fill so the
   swap hook is trivially verifiable in a screenshot */
static void OvDrawButton(int x0, int y0, int x1, int y1)
{
    /* 1px gold frame */
    glDisable(GL_TEXTURE_2D);
    glColor4f(0.82f, 0.64f, 0.24f, 0.95f);
    glBegin(GL_QUADS);
    glVertex2i(x0, y0); glVertex2i(x1, y0); glVertex2i(x1, y1); glVertex2i(x0, y1);
    glEnd();

    /* inner plate */
    glColor4f(0.10f, 0.08f, 0.05f, 0.92f);
    glBegin(GL_QUADS);
    glVertex2i(x0 + 2, y0 + 2); glVertex2i(x1 - 2, y0 + 2);
    glVertex2i(x1 - 2, y1 - 2); glVertex2i(x0 + 2, y1 - 2);
    glEnd();

    /* marker: bright magenta square in the middle (S1 verification) */
    const int mx0 = x0 + 8, my0 = y0 + 8, mx1 = x1 - 8, my1 = y1 - 8;
    if (mx1 > mx0 && my1 > my0)
    {
        glColor4f(1.0f, 0.10f, 0.85f, 1.0f);
        glBegin(GL_QUADS);
        glVertex2i(mx0, my0); glVertex2i(mx1, my0); glVertex2i(mx1, my1); glVertex2i(mx0, my1);
        glEnd();
    }
}

/* --------------------------------------------------------------- the draw */
static void OvMaybeDumpFrame(int cw, int ch);

typedef void (APIENTRY* fn_bind_fb_t)(GLenum, GLuint);
static fn_bind_fb_t OvBindFb(void)
{
    static fn_bind_fb_t fn = NULL;
    static int tried = 0;
    if (!tried)
    {
        tried = 1;
        fn = (fn_bind_fb_t)wglGetProcAddress("glBindFramebuffer");
        if (!fn) fn = (fn_bind_fb_t)wglGetProcAddress("glBindFramebufferEXT");
    }
    return fn;
}

/* The game binds its own GLSL program and VAO for world rendering. A bound
   program transforms our immediate-mode vertices with attributes that were
   never fed, so the quad silently disappears and glGetError() stays 0. Until
   this was handled, only the loading screen (fixed pipeline) showed the
   overlay. */
typedef void (APIENTRY* fn_use_program_t)(GLuint);
typedef void (APIENTRY* fn_bind_vao_t)(GLuint);

static fn_use_program_t OvUseProgram(void)
{
    static fn_use_program_t fn = NULL;
    static int tried = 0;
    if (!tried)
    {
        tried = 1;
        fn = (fn_use_program_t)wglGetProcAddress("glUseProgram");
        if (!fn) fn = (fn_use_program_t)wglGetProcAddress("glUseProgramObjectARB");
    }
    return fn;
}

static fn_bind_vao_t OvBindVao(void)
{
    static fn_bind_vao_t fn = NULL;
    static int tried = 0;
    if (!tried)
    {
        tried = 1;
        fn = (fn_bind_vao_t)wglGetProcAddress("glBindVertexArray");
        if (!fn) fn = (fn_bind_vao_t)wglGetProcAddress("glBindVertexArrayAPPLE");
    }
    return fn;
}

/* Paint one rectangle with glClear + scissor. This deliberately avoids the
   vertex pipeline: it ignores the matrix stack, any bound shader, lighting,
   fog and the blend equation, so it lands even when the game's GL state is
   exotic. War3's in-game frames swallowed every glBegin quad even though
   glGetError() stayed 0, so the button is painted this way for now. */
static void OvFillRectGl(int x, int yTop, int w, int h, int ch,
                         float r, float g, float b, float a)
{
    if (w <= 0 || h <= 0) return;
    glEnable(GL_SCISSOR_TEST);
    glScissor(x, ch - (yTop + h), w, h);      /* GL scissor origin is bottom-left */
    glClearColor(r, g, b, a);
    glClear(GL_COLOR_BUFFER_BIT);
    glDisable(GL_SCISSOR_TEST);
}

/* ---- WebView2 frame channel ------------------------------------------------
   ddh_web.dll (a .NET/WebView2 host started from here) renders the HTML page
   and publishes BGRA frames into Local\DdhHtml_<gamePid>:
       int32 magic 'DHH1' | int32 w | int32 h | int32 seq | int32 tick
       BGRA rows, top-down, at offset 64
   The overlay copies a frame when seq changes and blits it with glDrawPixels
   (the immediate-mode path is swallowed by this game, glDrawPixels is not). */
#define OV_HTML_W     1200
#define OV_HTML_H     760
#define OV_HTML_HDR   64
#define OV_HTML_INPUT 64
#define OV_HTML_MAGIC 0x31484844   /* 'DHH1' */

static HANDLE         g_htmlMap = NULL;
static unsigned char* g_htmlView = NULL;
static unsigned char* g_htmlFlip = NULL;
static int            g_htmlSeq = 0;
static int            g_htmlReady = 0;
static char           g_htmlPath[MAX_PATH] = { 0 };
static volatile LONG  g_htmlSpawned = 0;
static HANDLE         g_htmlProcess = NULL;
static DWORD          g_htmlLastSpawnTick = 0;
static int            g_htmlExplorerLaunchPending = 0;
static DWORD          g_htmlStateLogTick = 0;
static volatile LONG  g_htmlPreviousSpawnState = 0;
static unsigned char* g_staticHtmlPixels = NULL;
static int            g_staticHtmlW = 0;
static int            g_staticHtmlH = 0;
static int            g_staticHtmlTried = 0;

extern "C" int DdhGetCurrentSessionId(char* out, int capacity);

static void OvSetSpawnState(int state, unsigned long detail1 = 0, unsigned long detail2 = 0)
{
    if (!g_htmlView) return;
    volatile LONG* header = (volatile LONG*)g_htmlView;
    const LONG previous = InterlockedExchange(&g_htmlPreviousSpawnState, (LONG)state);
    InterlockedExchange(&header[5], (LONG)state);
    InterlockedExchange(&header[6], (LONG)detail1);
    InterlockedExchange(&header[7], previous);
    InterlockedExchange(&header[8], (LONG)detail2);
    if (state >= 20 && state <= 23)
        InterlockedExchange(&header[9], ((LONG)state << 24) | ((LONG)detail1 & 0xFFFFFF));
    MemoryBarrier();
}

static void OvHostLaunchLog(const char* fmt, ...)
{
    char text[512] = { 0 };
    va_list ap;
    va_start(ap, fmt);
    _vsnprintf_s(text, sizeof(text), _TRUNCATE, fmt, ap);
    va_end(ap);

    char line[640] = { 0 };
    SYSTEMTIME st;
    GetLocalTime(&st);
    _snprintf_s(line, sizeof(line), _TRUNCATE,
                "[%02d:%02d:%02d.%03d] [%lu] %s\r\n",
                st.wHour, st.wMinute, st.wSecond, st.wMilliseconds,
                (unsigned long)GetCurrentProcessId(), text);
    CreateDirectoryA(OV_SHARED_DIR, NULL);
    char temp[MAX_PATH] = { 0 };
    if (GetTempPathA((DWORD)sizeof(temp), temp) == 0) temp[0] = 0;
    if (temp[0]) strcat_s(temp, sizeof(temp), "ddh-host-launch.txt");
    const char* paths[] =
    {
        OV_SHARED_DIR "\\ddh-host-launch.txt",
        "C:\\launch\\ddh-host-launch.txt",
        temp[0] ? temp : NULL,
    };
    for (int i = 0; i < (int)(sizeof(paths) / sizeof(paths[0])); ++i)
    {
        if (!paths[i] || !paths[i][0]) continue;
        HANDLE h = CreateFileA(paths[i], FILE_APPEND_DATA,
                               FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_ALWAYS,
                               FILE_ATTRIBUTE_NORMAL, NULL);
        if (h == INVALID_HANDLE_VALUE) continue;
        DWORD written = 0;
        WriteFile(h, line, (DWORD)strlen(line), &written, NULL);
        CloseHandle(h);
        return;
    }
}

static void OvHtmlOpen(void)
{
    if (g_htmlView) return;
    char name[128] = { 0 };
    _snprintf_s(name, sizeof(name), _TRUNCATE, "Local\\DdhHtml_%lu",
                (unsigned long)GetCurrentProcessId());
    const int size = OV_HTML_HDR + OV_HTML_W * OV_HTML_H * 4 + OV_HTML_INPUT;
    g_htmlMap = CreateFileMappingA(INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE, 0, size, name);
    if (!g_htmlMap) { OvLog("html map failed err=%lu", GetLastError()); return; }
    g_htmlView = (unsigned char*)MapViewOfFile(g_htmlMap, FILE_MAP_ALL_ACCESS, 0, 0, size);
    if (!g_htmlView) { OvLog("html view failed err=%lu", GetLastError()); return; }
    g_htmlFlip = (unsigned char*)malloc(OV_HTML_W * OV_HTML_H * 4);
    OvLog("html map %s view=%p", name, (void*)g_htmlView);
}

/*
 * Let the game own the frame mapping before the higher-integrity desktop
 * helper starts. A low-integrity War3 cannot obtain write access to a default
 * medium-integrity mapping created by ddh_web, while ddh_web can write down
 * into a mapping created here.
 */
extern "C" int DdhOverlayEnsureHtmlMapping(void)
{
    OvHtmlOpen();
    return g_htmlView != NULL;
}

typedef BOOL (WINAPI* fn_open_process_token_t)(HANDLE, DWORD, PHANDLE);
typedef BOOL (WINAPI* fn_duplicate_token_ex_t)(
    HANDLE, DWORD, LPSECURITY_ATTRIBUTES, SECURITY_IMPERSONATION_LEVEL,
    TOKEN_TYPE, PHANDLE);
typedef BOOL (WINAPI* fn_create_process_with_token_t)(
    HANDLE, DWORD, LPCWSTR, LPWSTR, DWORD, LPVOID, LPCWSTR,
    LPSTARTUPINFOW, LPPROCESS_INFORMATION);

/*
 * Some non-platform launchers attach restrictive process mitigation policies
 * to War3. A directly inherited ddh_web child starts but is terminated before
 * managed Main can create WebView2. Launch it with the same desktop user's
 * Explorer token instead, which keeps the helper outside that child policy.
 */
static int OvSpawnWithExplorerToken(const char* commandLine, const char* workDir,
                                    PROCESS_INFORMATION* pi)
{
    if (!commandLine || !workDir || !pi) return 0;
    HMODULE advapi = GetModuleHandleA("advapi32.dll");
    if (!advapi) return 0;
    fn_open_process_token_t openToken =
        (fn_open_process_token_t)GetProcAddress(advapi, "OpenProcessToken");
    fn_duplicate_token_ex_t duplicateToken =
        (fn_duplicate_token_ex_t)GetProcAddress(advapi, "DuplicateTokenEx");
    fn_create_process_with_token_t createWithToken =
        (fn_create_process_with_token_t)GetProcAddress(advapi, "CreateProcessWithTokenW");
    if (!openToken || !duplicateToken || !createWithToken) return 0;

    DWORD sessionId = 0;
    ProcessIdToSessionId(GetCurrentProcessId(), &sessionId);
    HANDLE explorer = NULL;
    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snapshot != INVALID_HANDLE_VALUE)
    {
        PROCESSENTRY32 pe;
        memset(&pe, 0, sizeof(pe));
        pe.dwSize = sizeof(pe);
        if (Process32First(snapshot, &pe))
        {
            do
            {
                if (_stricmp(pe.szExeFile, "explorer.exe") != 0) continue;
                DWORD candidateSession = 0;
                if (!ProcessIdToSessionId(pe.th32ProcessID, &candidateSession) ||
                    candidateSession != sessionId)
                    continue;
                explorer = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pe.th32ProcessID);
                if (explorer) break;
            } while (Process32Next(snapshot, &pe));
        }
        CloseHandle(snapshot);
    }
    if (!explorer)
    {
        OvHostLaunchLog("desktop token unavailable: explorer not found");
        return 0;
    }

    HANDLE token = NULL;
    HANDLE primary = NULL;
    int ok = 0;
    if (openToken(explorer, TOKEN_DUPLICATE | TOKEN_QUERY, &token))
    {
        if (duplicateToken(token, MAXIMUM_ALLOWED, NULL, SecurityImpersonation,
                           TokenPrimary, &primary))
        {
            wchar_t wideCmd[1024] = { 0 };
            wchar_t wideDir[1024] = { 0 };
            MultiByteToWideChar(CP_ACP, 0, commandLine, -1, wideCmd, 1024);
            MultiByteToWideChar(CP_ACP, 0, workDir, -1, wideDir, 1024);
            STARTUPINFOW si;
            memset(&si, 0, sizeof(si));
            si.cb = sizeof(si);
            memset(pi, 0, sizeof(*pi));
            ok = createWithToken(primary, 0, NULL, wideCmd,
                                 CREATE_NO_WINDOW | CREATE_BREAKAWAY_FROM_JOB,
                                 NULL, wideDir, &si, pi) ? 1 : 0;
            if (!ok)
                OvHostLaunchLog("CreateProcessWithTokenW failed err=%lu", GetLastError());
        }
    }
    if (primary) CloseHandle(primary);
    if (token) CloseHandle(token);
    CloseHandle(explorer);
    return ok;
}

/*
 * Launch through a fixed desktop script instead of creating a .lnk at runtime.
 * The game process may have COM disabled, may be inside a restricted Job, or
 * may not be allowed to write shared files. Explorer executes the script in
 * its own desktop context and receives all dynamic arguments directly.
 */
static int OvSpawnViaExplorerLauncher(const char* parameters)
{
    const char* launcherPath = "C:\\launch\\ddh_web_launcher.cmd";
    if (!parameters || !parameters[0]) return 0;
    if (GetFileAttributesA(launcherPath) == INVALID_FILE_ATTRIBUTES)
    {
        OvHostLaunchLog("fixed launcher missing: %s", launcherPath);
        return 0;
    }

    SHELLEXECUTEINFOA sei;
    memset(&sei, 0, sizeof(sei));
    sei.cbSize = sizeof(sei);
    sei.fMask = SEE_MASK_FLAG_NO_UI | SEE_MASK_NOASYNC;
    sei.lpFile = launcherPath;
    sei.lpParameters = parameters;
    sei.nShow = SW_HIDE;
    if (!ShellExecuteExA(&sei))
    {
        OvHostLaunchLog("explorer launcher failed path=%s err=%lu",
                        launcherPath, GetLastError());
        return 0;
    }
    return 1;
}

static int OvSpawnViaWmiLauncher(const char* parameters)
{
    const char* scriptPath = "C:\\launch\\ddh_web_launcher.ps1";
    if (!parameters || !parameters[0]) return 0;
    if (GetFileAttributesA(scriptPath) == INVALID_FILE_ATTRIBUTES)
    {
        OvHostLaunchLog("WMI launcher missing: %s", scriptPath);
        return 0;
    }

    char command[2048] = { 0 };
    _snprintf_s(command, sizeof(command), _TRUNCATE,
                "\"C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe\" "
                "-NoProfile -NonInteractive -WindowStyle Hidden "
                "-ExecutionPolicy Bypass -File \"%s\" %s",
                scriptPath, parameters);

    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    memset(&si, 0, sizeof(si));
    si.cb = sizeof(si);
    memset(&pi, 0, sizeof(pi));
    if (!CreateProcessA(NULL, command, NULL, NULL, FALSE, CREATE_NO_WINDOW,
                        NULL, "C:\\launch", &si, &pi))
    {
        OvHostLaunchLog("WMI launcher CreateProcess failed err=%lu", GetLastError());
        return 0;
    }
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return 1;
}

static void OvSpawnHost(const char* html)
{
    if (!html || !html[0]) return;
    OvSetSpawnState(1);
    const DWORD stateNow = GetTickCount();
    if (!g_htmlStateLogTick || stateNow - g_htmlStateLogTick >= 5000)
    {
        g_htmlStateLogTick = stateNow;
        OvHostLaunchLog("spawn enter game_pid=%lu pending=%d process=%p elapsed=%lu",
                        (unsigned long)GetCurrentProcessId(),
                        g_htmlExplorerLaunchPending, (void*)g_htmlProcess,
                        (unsigned long)(stateNow - g_htmlLastSpawnTick));
    }
    const char* exePath = "C:\\launch\\ddh_web\\ddh_web.exe";
    const char* workDir = "C:\\launch\\ddh_web";
    if (GetFileAttributesA(exePath) == INVALID_FILE_ATTRIBUTES)
    {
        OvSetSpawnState(2, GetLastError());
        OvLog("html host missing: %s", exePath);
        OvHostLaunchLog("html host missing game_pid=%lu path=%s",
                        (unsigned long)GetCurrentProcessId(), exePath);
        return;
    }

    char cmd[1024] = { 0 };
    char params[1024] = { 0 };
    const char* marker = DdhOverlayMarkerText();
    char sessionId[24] = { 0 };
    char sessionArg[64] = { 0 };
    if (DdhGetCurrentSessionId(sessionId, (int)sizeof(sessionId)) && sessionId[0])
    {
        _snprintf_s(sessionArg, sizeof(sessionArg), _TRUNCATE,
                    " --session \"%s\"", sessionId);
    }
    OvHostLaunchLog("spawn params game_pid=%lu session=%s marker=%s",
                    (unsigned long)GetCurrentProcessId(),
                    sessionId[0] ? sessionId : "<empty>", marker);
    _snprintf_s(cmd, sizeof(cmd), _TRUNCATE,
                "\"%s\" --pid %lu --html \"%s\" --w %d --h %d%s --log \"%s\" --ddh-marker \"%s\"",
                exePath, (unsigned long)GetCurrentProcessId(), html,
                OV_HTML_W, OV_HTML_H, sessionArg, OV_LOG_DIR "\\ddh-web.txt", marker);
    _snprintf_s(params, sizeof(params), _TRUNCATE,
                "--pid %lu --html \"%s\" --w %d --h %d%s --log \"%s\" --ddh-marker \"%s\"",
                (unsigned long)GetCurrentProcessId(), html,
                OV_HTML_W, OV_HTML_H, sessionArg, OV_LOG_DIR "\\ddh-web.txt", marker);

    if (g_htmlExplorerLaunchPending)
    {
        OvSetSpawnState(3, (unsigned long)(GetTickCount() - g_htmlLastSpawnTick));
        const DWORD elapsed = GetTickCount() - g_htmlLastSpawnTick;
        if (elapsed < 15000)
        {
            OvHostLaunchLog("spawn deferred game_pid=%lu elapsed=%lu",
                            (unsigned long)GetCurrentProcessId(),
                            (unsigned long)elapsed);
            return;
        }
        g_htmlExplorerLaunchPending = 0;
    }
    if (g_htmlProcess)
    {
        if (WaitForSingleObject(g_htmlProcess, 0) == WAIT_TIMEOUT)
        {
            OvSetSpawnState(4, (unsigned long)(uintptr_t)g_htmlProcess);
            OvHostLaunchLog("spawn skipped game_pid=%lu existing_process=%p",
                            (unsigned long)GetCurrentProcessId(),
                            (void*)g_htmlProcess);
            return;
        }
        CloseHandle(g_htmlProcess);
        g_htmlProcess = NULL;
    }
    g_htmlLastSpawnTick = GetTickCount();

    PROCESS_INFORMATION desktop;
    if (OvSpawnWithExplorerToken(cmd, workDir, &desktop))
    {
        OvSetSpawnState(6, desktop.dwProcessId);
        OvLog("html host started with Explorer token pid=%lu",
              (unsigned long)desktop.dwProcessId);
        OvHostLaunchLog("Explorer-token-first ok pid=%lu",
                        (unsigned long)desktop.dwProcessId);
        CloseHandle(desktop.hThread);
        g_htmlProcess = desktop.hProcess;
        g_htmlLastSpawnTick = GetTickCount();
        return;
    }

    if (OvSpawnViaExplorerLauncher(params))
    {
        OvSetSpawnState(7);
        g_htmlExplorerLaunchPending = 1;
        g_htmlLastSpawnTick = GetTickCount();
        OvLog("html host requested through fixed Explorer launcher");
        OvHostLaunchLog("Explorer-launcher requested game_pid=%lu",
                        (unsigned long)GetCurrentProcessId());
        return;
    }
    OvHostLaunchLog("Explorer-launcher failed err=%lu", GetLastError());

    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    memset(&si, 0, sizeof(si));
    si.cb = sizeof(si);
    memset(&pi, 0, sizeof(pi));
    /*
     * Non-platform launchers may place War3 inside a Windows Job object.
     * Inheriting that Job can prevent WebView2 from creating its browser
     * subprocesses, leaving ddh_web alive without a renderer. Prefer a
     * breakaway child; if the Job forbids breakaway, fall through to the
     * desktop-shell launch below.
     */
    const DWORD creationFlags = CREATE_NO_WINDOW | CREATE_BREAKAWAY_FROM_JOB;
    if (CreateProcessA(NULL, cmd, NULL, NULL, FALSE, creationFlags, NULL, workDir, &si, &pi))
    {
        OvSetSpawnState(8, pi.dwProcessId);
        OvLog("html host started pid=%lu flags=0x%lX", (unsigned long)pi.dwProcessId, creationFlags);
        OvHostLaunchLog("CreateProcess ok pid=%lu flags=0x%lX",
                        (unsigned long)pi.dwProcessId, creationFlags);
        CloseHandle(pi.hThread);
        g_htmlProcess = pi.hProcess;
        g_htmlLastSpawnTick = GetTickCount();
        return;
    }

    const DWORD processError = GetLastError();
    OvLog("html host breakaway failed err=%lu; trying ShellExecuteEx", processError);
    OvHostLaunchLog("CreateProcess failed err=%lu flags=0x%lX", processError, creationFlags);

    SHELLEXECUTEINFOA shell;
    memset(&shell, 0, sizeof(shell));
    shell.cbSize = sizeof(shell);
    shell.fMask = SEE_MASK_NOCLOSEPROCESS | SEE_MASK_FLAG_NO_UI | SEE_MASK_NOASYNC;
    shell.lpFile = exePath;
    shell.lpParameters = params;
    shell.lpDirectory = workDir;
    shell.nShow = SW_HIDE;
    if (ShellExecuteExA(&shell))
    {
        OvSetSpawnState(9, shell.hProcess ? GetProcessId(shell.hProcess) : 0);
        OvLog("html host started via shell pid=%lu",
              shell.hProcess ? (unsigned long)GetProcessId(shell.hProcess) : 0ul);
        OvHostLaunchLog("ShellExecuteEx ok pid=%lu",
                        shell.hProcess ? (unsigned long)GetProcessId(shell.hProcess) : 0ul);
        if (shell.hProcess) g_htmlProcess = shell.hProcess;
        g_htmlLastSpawnTick = GetTickCount();
        return;
    }
    OvLog("html host shell start failed create_err=%lu shell_err=%lu",
          processError, GetLastError());
    OvSetSpawnState(10, processError, GetLastError());
    OvHostLaunchLog("ShellExecuteEx failed create_err=%lu shell_err=%lu",
                    processError, GetLastError());

    /* WMI is a last-resort request. Its PowerShell process can be created
       successfully while the real WebHost is still blocked by War3's Job, so
       it must not prevent the Explorer-token and breakaway paths above. */
    if (OvSpawnViaWmiLauncher(params))
    {
        OvSetSpawnState(5);
        g_htmlExplorerLaunchPending = 1;
        g_htmlLastSpawnTick = GetTickCount();
        OvLog("html host requested through WMI fallback");
        OvHostLaunchLog("WMI-launcher fallback requested game_pid=%lu",
                        (unsigned long)GetCurrentProcessId());
        return;
    }
    OvHostLaunchLog("WMI-launcher fallback failed game_pid=%lu",
                    (unsigned long)GetCurrentProcessId());
}

extern "C" void DdhOverlaySetHtml(const char* html)
{
    if (!html || !html[0]) return;
    strncpy_s(g_htmlPath, sizeof(g_htmlPath), html, _TRUNCATE);
    OvHtmlOpen();
    InterlockedExchange(&g_htmlSpawned, 1);
    OvSpawnHost(g_htmlPath);
    OvLog("html requested: %s", g_htmlPath);
}

extern "C" void DdhOverlayRestartHtml(const char* html)
{
    if (!html || !html[0]) return;
    if (g_htmlProcess)
    {
        if (WaitForSingleObject(g_htmlProcess, 0) == WAIT_TIMEOUT)
            TerminateProcess(g_htmlProcess, 0);
        WaitForSingleObject(g_htmlProcess, 1500);
        CloseHandle(g_htmlProcess);
        g_htmlProcess = NULL;
    }
    strncpy_s(g_htmlPath, sizeof(g_htmlPath), html, _TRUNCATE);
    OvHtmlOpen();
    InterlockedExchange(&g_htmlSpawned, 1);
    OvSpawnHost(g_htmlPath);
    OvLog("html host restart requested: %s", g_htmlPath);
    OvHostLaunchLog("force restart game_pid=%lu", (unsigned long)GetCurrentProcessId());
}

/* copy the newest published frame (flipped for glDrawPixels) */
static int OvHtmlRefresh(void)
{
    if (!g_htmlView || !g_htmlFlip) return 0;
    const int magic = *(const int*)(g_htmlView + 0);
    const int w = *(const int*)(g_htmlView + 4);
    const int h = *(const int*)(g_htmlView + 8);
    const int seq = *(const int*)(g_htmlView + 12);
    if (magic != OV_HTML_MAGIC || w <= 0 || h <= 0 || w > OV_HTML_W || h > OV_HTML_H ||
        seq == 0)
    {
        const DWORD now = GetTickCount();
        if (g_htmlPath[0] && (DWORD)(now - g_htmlLastSpawnTick) >= 2000)
            OvSpawnHost(g_htmlPath);
        return 0;
    }
    if (seq != g_htmlSeq)
    {
        const unsigned char* src = g_htmlView + OV_HTML_HDR;
        const size_t stride = (size_t)w * 4;
        for (int y = 0; y < h; ++y)
            memcpy(g_htmlFlip + (size_t)(h - 1 - y) * stride, src + (size_t)y * stride, stride);
        g_htmlSeq = seq;
        if (g_htmlReady == 0)
        {
            g_htmlReady = 1;
            const unsigned char* mid = g_htmlFlip + (size_t)(h / 2) * stride + (size_t)(w / 2) * 4;
            OvLog("html first frame %dx%d center BGRA=%u,%u,%u,%u",
                  w, h, mid[0], mid[1], mid[2], mid[3]);
        }
    }
    return 1;
}

/* 固定 dss.html 的离线快照。WebView2 暂不可用时仍能立即显示页面，
   不再让覆盖层窗口停留在全透明状态。 */
static int OvStaticHtmlRefresh(void)
{
    if (g_staticHtmlPixels) return 1;
    if (g_staticHtmlTried) return 0;
    g_staticHtmlTried = 1;

    HANDLE h = CreateFileA("C:\\launch\\ddh_dss.bgra", GENERIC_READ,
                           FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING,
                           FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE) return 0;

    LARGE_INTEGER size;
    if (!GetFileSizeEx(h, &size) || size.QuadPart < 8)
    {
        CloseHandle(h);
        return 0;
    }
    int wh[2] = { 0, 0 };
    DWORD got = 0;
    if (!ReadFile(h, wh, sizeof(wh), &got, NULL) || got != sizeof(wh) ||
        wh[0] != OV_HTML_W || wh[1] != OV_HTML_H ||
        size.QuadPart != 8 + (LONGLONG)OV_HTML_W * OV_HTML_H * 4)
    {
        CloseHandle(h);
        return 0;
    }

    unsigned char* pixels = (unsigned char*)malloc((size_t)OV_HTML_W * OV_HTML_H * 4);
    if (!pixels)
    {
        CloseHandle(h);
        return 0;
    }
    const DWORD want = OV_HTML_W * OV_HTML_H * 4;
    if (!ReadFile(h, pixels, want, &got, NULL) || got != want)
    {
        free(pixels);
        CloseHandle(h);
        return 0;
    }
    CloseHandle(h);
    g_staticHtmlPixels = pixels;
    g_staticHtmlW = OV_HTML_W;
    g_staticHtmlH = OV_HTML_H;
    OvLog("static html snapshot loaded %dx%d", g_staticHtmlW, g_staticHtmlH);
    return 1;
}

typedef void (APIENTRY* fn_blend_eq_t)(GLenum);
static fn_blend_eq_t OvBlendEq(void)
{
    static fn_blend_eq_t fn = NULL;
    static int tried = 0;
    if (!tried)
    {
        tried = 1;
        fn = (fn_blend_eq_t)wglGetProcAddress("glBlendEquation");
        if (!fn) fn = (fn_blend_eq_t)wglGetProcAddress("glBlendEquationEXT");
    }
    return fn;
}

typedef void (APIENTRY* fn_wpos2i_t)(GLint, GLint);
static fn_wpos2i_t OvWindowPos(void)
{
    static fn_wpos2i_t fn = NULL;
    static int tried = 0;
    if (!tried)
    {
        tried = 1;
        fn = (fn_wpos2i_t)wglGetProcAddress("glWindowPos2i");
        if (!fn) fn = (fn_wpos2i_t)wglGetProcAddress("glWindowPos2iARB");
    }
    return fn;
}

/* set the raster position without going through the transform pipeline: the
   transformed position is clipped against the clip volume, and the game can
   leave clip planes enabled, which silently invalidates it (rasterValid=0 and
   glDrawPixels draws nothing at all). */
static void OvSetRasterPos(int x, int yTop, int ch)
{
    fn_wpos2i_t wp = OvWindowPos();
    if (wp) wp(x, ch - yTop);            /* window coords are bottom-up */
    else glRasterPos2i(x, yTop);
}

/* Blit a BGRA image with glDrawPixels using an identity transform, so the
   raster position is a plain NDC coordinate and cannot be distorted by the
   game's matrices or by our own ortho. (x, yTop) is the top-left corner in
   client pixels. Returns the raster-position validity for diagnostics. */
static int OvBlitNdc(int x, int yTop, int w, int h, int cw, int ch,
                     const unsigned char* data)
{
    if (w <= 0 || h <= 0) return 0;
    const float ndcX = (float)((double)x / (double)cw * 2.0 - 1.0);
    const float ndcBottom = (float)(1.0 - (double)(yTop + h) / (double)ch * 2.0);

    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();

    glViewport(0, 0, cw, ch);
    glRasterPos3f(ndcX, ndcBottom, 0.0f);

    GLboolean ok = GL_FALSE;
    glGetBooleanv(0x0B7C /*GL_CURRENT_RASTER_POSITION_VALID*/, &ok);

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    glPixelStorei(GL_UNPACK_SKIP_ROWS, 0);
    glPixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
    glPixelZoom(1.0f, 1.0f);
    glDrawPixels(w, h, GL_BGRA, GL_UNSIGNED_BYTE, data);

    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    return ok ? 1 : 0;
}

static int OvBlitTopDown(int x, int yTop, int w, int h, int cw, int ch,
                         const unsigned char* data)
{
    if (!data || w <= 0 || h <= 0) return 0;

    static unsigned char* flipped = NULL;
    static size_t capacity = 0;
    const size_t need = (size_t)w * (size_t)h * 4;
    if (!flipped || capacity < need)
    {
        if (flipped) free(flipped);
        flipped = (unsigned char*)malloc(need);
        capacity = flipped ? need : 0;
        if (!flipped) return 0;
    }

    const size_t rowBytes = (size_t)w * 4;
    for (int y = 0; y < h; ++y)
        memcpy(flipped + (size_t)(h - 1 - y) * rowBytes,
               data + (size_t)y * rowBytes, rowBytes);
    return OvBlitNdc(x, yTop, w, h, cw, ch, flipped);
}

/* ---- HTML panel as a layered window ---------------------------------------
   Drawing the page into the game's GL frame works but is fragile (the raster
   position is silently invalidated in some states) and, worse, the game's own
   software cursor is then covered by the panel. The platform-style solution
   (what KK/WFE do) is a separate layered, click-through window: the OS
   composites it above the game and the cursor above the window, so the pointer
   can never be hidden by our UI. */
static HWND    g_ovLw = NULL;
static HDC     g_ovLwScreenDc = NULL;
static HDC     g_ovLwMemDc = NULL;
static HBITMAP g_ovLwBmp = NULL;
static void*   g_ovLwBits = NULL;
static int     g_ovLwW = 0, g_ovLwH = 0;
static int     g_ovLwSeq = -1;
static int     g_ovLwShown = 0;

static void OvLwDestroy(void)
{
    if (g_ovLw) { DestroyWindow(g_ovLw); g_ovLw = NULL; }
    if (g_ovLwBmp) { DeleteObject(g_ovLwBmp); g_ovLwBmp = NULL; }
    if (g_ovLwMemDc) { DeleteDC(g_ovLwMemDc); g_ovLwMemDc = NULL; }
    if (g_ovLwScreenDc) { ReleaseDC(NULL, g_ovLwScreenDc); g_ovLwScreenDc = NULL; }
    g_ovLwBits = NULL;
    g_ovLwShown = 0;
    g_ovLwSeq = -1;
}

static int OvLwEnsure(int w, int h)
{
    if (g_ovLw && g_ovLwW == w && g_ovLwH == h) return 1;
    OvLwDestroy();

    WNDCLASSA wc;
    memset(&wc, 0, sizeof(wc));
    wc.lpfnWndProc = DefWindowProcA;
    wc.hInstance = GetModuleHandleA(NULL);
    wc.lpszClassName = "DdhOverlayPanelWnd";
    wc.hCursor = LoadCursorW(NULL, (LPCWSTR)IDC_ARROW);
    RegisterClassA(&wc);   /* already registered on later calls: ignore failure */

    g_ovLw = CreateWindowExA(
        WS_EX_LAYERED | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_TRANSPARENT,
        "DdhOverlayPanelWnd", "", WS_POPUP,
        0, 0, w, h, g_ovWnd, NULL, wc.hInstance, NULL);
    if (!g_ovLw) { OvLog("layered window create failed err=%lu", GetLastError()); return 0; }

    g_ovLwScreenDc = GetDC(NULL);
    g_ovLwMemDc = CreateCompatibleDC(g_ovLwScreenDc);

    BITMAPINFO bmi;
    memset(&bmi, 0, sizeof(bmi));
    bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bmi.bmiHeader.biWidth = w;
    bmi.bmiHeader.biHeight = -h;              /* top-down */
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = BI_RGB;
    g_ovLwBmp = CreateDIBSection(g_ovLwMemDc, &bmi, DIB_RGB_COLORS, &g_ovLwBits, NULL, 0);
    if (!g_ovLwBmp || !g_ovLwBits)
    {
        OvLog("layered dib failed err=%lu", GetLastError());
        OvLwDestroy();
        return 0;
    }
    SelectObject(g_ovLwMemDc, g_ovLwBmp);
    g_ovLwW = w;
    g_ovLwH = h;
    OvLog("layered panel window %dx%d created", w, h);
    return 1;
}

static void OvLwPush(int px, int py)
{
    if (!g_htmlView || !g_ovWnd) return;
    if (!OvHtmlRefresh()) return;
    const int w = *(const int*)(g_htmlView + 4);
    const int h = *(const int*)(g_htmlView + 8);
    if (w <= 0 || h <= 0) return;
    if (!OvLwEnsure(w, h)) return;

    /* the shared frame is top-down BGRA; UpdateLayeredWindow wants premultiplied
       ARGB, and the page is opaque, so alpha := 255 and the colours stay */
    const unsigned char* src = g_htmlView + OV_HTML_HDR;
    unsigned char* dst = (unsigned char*)g_ovLwBits;
    const size_t n = (size_t)w * h;
    memcpy(dst, src, n * 4);
    for (size_t i = 0; i < n; ++i) dst[i * 4 + 3] = 255;

    /* position: client (px,py) -> screen */
    POINT ptDst = { px, py };
    if (!ClientToScreen(g_ovWnd, &ptDst)) return;

    SIZE size = { w, h };
    POINT ptSrc = { 0, 0 };
    BLENDFUNCTION bf;
    bf.BlendOp = AC_SRC_OVER;
    bf.BlendFlags = 0;
    bf.SourceConstantAlpha = 255;
    bf.AlphaFormat = AC_SRC_ALPHA;

    if (!UpdateLayeredWindow(g_ovLw, g_ovLwScreenDc, &ptDst, &size,
                             g_ovLwMemDc, &ptSrc, 0, &bf, ULW_ALPHA))
    {
        static int once = 0;
        if (!once) { once = 1; OvLog("UpdateLayeredWindow failed err=%lu", GetLastError()); }
        return;
    }
    if (!g_ovLwShown)
    {
        ShowWindow(g_ovLw, SW_SHOWNOACTIVATE);
        SetWindowPos(g_ovLw, HWND_TOP, 0, 0, 0, 0,
                     SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
        g_ovLwShown = 1;
        OvLog("layered panel shown");
    }
}

static void OvLwHide(void)
{
    if (g_ovLw && g_ovLwShown)
    {
        ShowWindow(g_ovLw, SW_HIDE);
        g_ovLwShown = 0;
        OvLog("layered panel hidden");
    }
}

static void OvBlitHtml(int px0, int py0, int cw, int ch)
{
    if (!OvHtmlRefresh()) return;
    const int w = *(const int*)(g_htmlView + 4);
    const int h = *(const int*)(g_htmlView + 8);
    glDisable(GL_TEXTURE_2D);
    fn_blend_eq_t be = OvBlendEq();
    if (be) be(GL_FUNC_ADD);
    /* opaque page for now: blending costs us a whole class of failure modes */
    glDisable(GL_BLEND);
    glDisable(GL_ALPHA_TEST);
    glPixelTransferi(GL_MAP_COLOR, GL_FALSE);
    glPixelTransferf(GL_RED_SCALE, 1.0f);
    glPixelTransferf(GL_GREEN_SCALE, 1.0f);
    glPixelTransferf(GL_BLUE_SCALE, 1.0f);
    glPixelTransferf(GL_ALPHA_SCALE, 1.0f);
    glPixelTransferf(GL_RED_BIAS, 0.0f);
    glPixelTransferf(GL_GREEN_BIAS, 0.0f);
    glPixelTransferf(GL_BLUE_BIAS, 0.0f);
    glPixelTransferf(GL_ALPHA_BIAS, 0.0f);

    static int s_blitLog = 0;
    const int ok = OvBlitNdc(px0, py0, w, h, cw, ch, g_htmlFlip);
    if (s_blitLog < 4)
    {
        ++s_blitLog;
        OvLog("html blit %dx%d at (%d,%d) rasterValid=%d err=%04X", w, h, px0, py0,
              ok, (unsigned)glGetError());
    }
}

/* War3 paints its own software cursor in the same frame we draw into, so our
   button would sit on top of the pointer. Draw a cursor arrow ourselves after
   the overlay content, but only where the pointer is over our own rectangles:
   everywhere else the game's cursor is already on top. */
#define OV_CUR_W 24
#define OV_CUR_H 32
static unsigned char s_ovArrow[OV_CUR_W * OV_CUR_H * 4];
static int s_ovArrowReady = 0;

static void OvBuildArrow(void)
{
    if (s_ovArrowReady) return;
    s_ovArrowReady = 1;
    for (int y = 0; y < OV_CUR_H; ++y)
    {
        for (int x = 0; x < OV_CUR_W; ++x)
        {
            /* glDrawPixels row 0 is the bottom row, so store flipped */
            unsigned char* p = &s_ovArrow[((OV_CUR_H - 1 - y) * OV_CUR_W + x) * 4];
            int inside = 0, edge = 0;
            if (y < 24)
            {
                const int right = (y * 3) / 4;
                if (x <= right) { inside = 1; if (x >= right - 1 || y >= 22) edge = 1; }
            }
            if (x >= 4 && x <= 9 && y >= 18 && y < 31)
            {
                inside = 1;
                if (x <= 4 || x >= 9 || y >= 30) edge = 1;
            }
            if (!inside) { p[0] = p[1] = p[2] = p[3] = 0; continue; }
            if (edge) { p[0] = p[1] = p[2] = 0; p[3] = 255; }
            else { p[0] = p[1] = p[2] = 255; p[3] = 255; }
        }
    }
}

static int OvPointInRect(const RECT& r, int x, int y)
{
    return r.right > r.left && x >= r.left && x < r.right && y >= r.top && y < r.bottom;
}

static void OvDrawCursorIfOver(int cw, int ch)
{
    if (!g_ovDrawCursor) return;          /* the OS cursor is composited above us */
    if (!g_ovWnd) return;
    POINT p;
    if (!GetCursorPos(&p)) return;
    if (!ScreenToClient(g_ovWnd, &p)) return;
    const int x = p.x, y = p.y;

    /* The game's cursor sprite is drawn before our overlay and is up to
       OV_CUR_H tall to the *left/above* of its hotspot, so test an expanded
       rectangle: with the hotspot just outside the panel the sprite is still
       partially covered, which is exactly what the user sees. */
    RECT btn = g_ovRect;
    RECT pan = g_ovPanelRect;
    btn.left -= OV_CUR_W; btn.top -= OV_CUR_H; btn.right += OV_CUR_W; btn.bottom += OV_CUR_H;
    pan.left -= OV_CUR_W; pan.top -= OV_CUR_H; pan.right += OV_CUR_W; pan.bottom += OV_CUR_H;
    const int overBtn = OvPointInRect(btn, x, y);
    const int overPanel = g_ovPanelVisible && OvPointInRect(pan, x, y);

    static DWORD s_lastLog = 0;
    const DWORD now = GetTickCount();
    if (now - s_lastLog > 1500)
    {
        s_lastLog = now;
        OvLog("cursor client=(%d,%d) overBtn=%d overPanel=%d panel=%d,%d..%d,%d",
              x, y, overBtn, overPanel,
              (int)g_ovPanelRect.left, (int)g_ovPanelRect.top,
              (int)g_ovPanelRect.right, (int)g_ovPanelRect.bottom);
    }
    if (!overBtn && !overPanel) return;

    OvBuildArrow();
    glDisable(GL_TEXTURE_2D);
    fn_blend_eq_t be = OvBlendEq();
    if (be) be(GL_FUNC_ADD);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_ALPHA_TEST);
    glPixelTransferi(GL_MAP_COLOR, GL_FALSE);
    /* same identity-transform blit the HTML frame uses: the ortho-based raster
       position was silently invalidated in this context */
    OvBlitNdc(x, y, OV_CUR_W, OV_CUR_H, cw, ch, s_ovArrow);
}

/* ---- button art ------------------------------------------------------------
   KK-platform-like 30x30 square icon in the top-right corner: dark plate, gold
   edge, one gold glyph. Drawn once with GDI into a bottom-up BGRA buffer and
   blitted with glDrawPixels (the quad path is swallowed by this game). */
static unsigned char s_btnArt[OV_BTN_W * OV_BTN_H * 4];
static int s_btnArtReady = 0;

static void OvBuildButtonArt(void)
{
    if (s_btnArtReady) return;
    s_btnArtReady = 1;
    const int w = OV_BTN_W, h = OV_BTN_H;

    BITMAPINFO bmi;
    memset(&bmi, 0, sizeof(bmi));
    bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bmi.bmiHeader.biWidth = w;
    bmi.bmiHeader.biHeight = -h;              /* top-down DIB */
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = BI_RGB;

    HDC screen = GetDC(NULL);
    HDC dc = CreateCompatibleDC(screen);
    if (screen) ReleaseDC(NULL, screen);
    if (!dc) return;

    void* bits = NULL;
    HBITMAP bmp = CreateDIBSection(dc, &bmi, DIB_RGB_COLORS, &bits, NULL, 0);
    if (!bmp || !bits) { DeleteDC(dc); return; }
    HGDIOBJ prev = SelectObject(dc, bmp);

    HBRUSH bg = CreateSolidBrush(RGB(24, 19, 12));
    HPEN pen = CreatePen(PS_SOLID, 1, RGB(214, 170, 74));
    HGDIOBJ ob = SelectObject(dc, bg);
    HGDIOBJ op = SelectObject(dc, pen);
    Rectangle(dc, 0, 0, w, h);
    SelectObject(dc, ob);
    SelectObject(dc, op);
    DeleteObject(bg);
    DeleteObject(pen);

    SetBkMode(dc, TRANSPARENT);
    SetTextColor(dc, RGB(255, 214, 120));
    HFONT font = CreateFontW(18, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
                             DEFAULT_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS,
                             ANTIALIASED_QUALITY, DEFAULT_PITCH, L"Microsoft YaHei");
    HGDIOBJ of = SelectObject(dc, font);
    RECT r = { 0, 0, w, h };
    wchar_t marker[2] = { (wchar_t)DdhOverlayMarkerText()[0], 0 };
    DrawTextW(dc, marker, -1, &r, DT_CENTER | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX);
    SelectObject(dc, of);
    DeleteObject(font);

    const unsigned char* src = (const unsigned char*)bits;
    for (int y = 0; y < h; ++y)
        memcpy(&s_btnArt[(size_t)(h - 1 - y) * w * 4], src + (size_t)y * w * 4, (size_t)w * 4);
    for (int i = 0; i < w * h; ++i) s_btnArt[i * 4 + 3] = 255;

    SelectObject(dc, prev);
    DeleteObject(bmp);
    DeleteDC(dc);
}

static void OvBlitButtonArt(int bx0, int by0, int cw, int ch)
{
    OvBuildButtonArt();
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_BLEND);
    glDisable(GL_ALPHA_TEST);
    glPixelTransferi(GL_MAP_COLOR, GL_FALSE);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    glPixelStorei(GL_UNPACK_SKIP_ROWS, 0);
    glPixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
    glPixelZoom(1.0f, 1.0f);
    OvBlitNdc(bx0, by0, OV_BTN_W, OV_BTN_H, cw, ch, s_btnArt);
}

/* ---- button as a layered window ------------------------------------------
   Same reason as the panel: anything drawn inside the GL frame can cover the
   game's software cursor. A 30x30 layered, click-through window is composited
   by the OS, so the system cursor stays above it. */
static HWND    g_ovBtnLw = NULL;
static HDC     g_ovBtnScreenDc = NULL;
static HDC     g_ovBtnMemDc = NULL;
static HBITMAP g_ovBtnBmp = NULL;
static void*   g_ovBtnBits = NULL;
static int     g_ovBtnShown = 0;

static int OvLwEnsureButton(void)
{
    if (g_ovBtnLw) return (g_ovBtnBits != NULL);
    if (!s_btnArtReady) OvBuildButtonArt();

    WNDCLASSA wc;
    memset(&wc, 0, sizeof(wc));
    wc.lpfnWndProc = DefWindowProcA;
    wc.hInstance = GetModuleHandleA(NULL);
    wc.lpszClassName = "DdhOverlayBtnWnd";
    wc.hCursor = LoadCursorW(NULL, (LPCWSTR)IDC_ARROW);
    RegisterClassA(&wc);

    g_ovBtnLw = CreateWindowExA(
        WS_EX_LAYERED | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_TRANSPARENT,
        "DdhOverlayBtnWnd", "", WS_POPUP,
        0, 0, OV_BTN_W, OV_BTN_H, g_ovWnd, NULL, wc.hInstance, NULL);
    if (!g_ovBtnLw) { OvLog("button window create failed err=%lu", GetLastError()); return 0; }

    g_ovBtnScreenDc = GetDC(NULL);
    g_ovBtnMemDc = CreateCompatibleDC(g_ovBtnScreenDc);

    BITMAPINFO bmi;
    memset(&bmi, 0, sizeof(bmi));
    bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bmi.bmiHeader.biWidth = OV_BTN_W;
    bmi.bmiHeader.biHeight = -OV_BTN_H;         /* top-down */
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = BI_RGB;
    g_ovBtnBmp = CreateDIBSection(g_ovBtnMemDc, &bmi, DIB_RGB_COLORS, &g_ovBtnBits, NULL, 0);
    if (!g_ovBtnBmp || !g_ovBtnBits) { OvLog("button dib failed err=%lu", GetLastError()); return 0; }
    SelectObject(g_ovBtnMemDc, g_ovBtnBmp);

    /* s_btnArt is bottom-up (for glDrawPixels); the layered window needs
       top-down rows */
    unsigned char* dst = (unsigned char*)g_ovBtnBits;
    for (int y = 0; y < OV_BTN_H; ++y)
        memcpy(dst + (size_t)y * OV_BTN_W * 4,
               s_btnArt + (size_t)(OV_BTN_H - 1 - y) * OV_BTN_W * 4,
               (size_t)OV_BTN_W * 4);
    for (int i = 0; i < OV_BTN_W * OV_BTN_H; ++i) dst[i * 4 + 3] = 255;
    OvLog("layered button window created");
    return 1;
}

static void OvLwButtonShow(int bx0, int by0)
{
    if (!g_ovWnd) return;
    if (!OvLwEnsureButton()) return;
    POINT ptDst = { bx0, by0 };
    if (!ClientToScreen(g_ovWnd, &ptDst)) return;
    SIZE size = { OV_BTN_W, OV_BTN_H };
    POINT ptSrc = { 0, 0 };
    BLENDFUNCTION bf;
    bf.BlendOp = AC_SRC_OVER;
    bf.BlendFlags = 0;
    bf.SourceConstantAlpha = 255;
    bf.AlphaFormat = AC_SRC_ALPHA;
    if (!UpdateLayeredWindow(g_ovBtnLw, g_ovBtnScreenDc, &ptDst, &size,
                             g_ovBtnMemDc, &ptSrc, 0, &bf, ULW_ALPHA)) return;
    if (!g_ovBtnShown)
    {
        ShowWindow(g_ovBtnLw, SW_SHOWNOACTIVATE);
        SetWindowPos(g_ovBtnLw, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
        g_ovBtnShown = 1;
    }
}

static void OvLwButtonHide(void)
{
    if (g_ovBtnLw && g_ovBtnShown) { ShowWindow(g_ovBtnLw, SW_HIDE); g_ovBtnShown = 0; }
}

/* ---- single composed overlay window --------------------------------------
   Button, panel and the pointer are composited into ONE layered, click-through
   window. The pointer is therefore a pixel drawn last *inside* the window that
   DWM keeps above the game, so nothing of ours can ever cover it again. */
static HWND    g_ovCw = NULL;
static HDC     g_ovCwScreen = NULL;
static HDC     g_ovCwMem = NULL;
static HBITMAP g_ovCwBmp = NULL;
static void*   g_ovCwBits = NULL;
static int     g_ovCwW = 0, g_ovCwH = 0;
static RECT    g_ovCwLocalBtn = { 0, 0, 0, 0 };   /* button rect inside the window */
static RECT    g_ovCwLocalPanel = { 0, 0, 0, 0 }; /* panel rect inside the window */
static int     g_ovCwShown = 0;
static int     g_ovCwFrameReady = 0;
static int     g_ovCwFrameX = 0, g_ovCwFrameY = 0;
static int     g_ovCwFrameW = 0, g_ovCwFrameH = 0;
static int     g_ovCwTracking = 0;

static void OvCwCopyTopDown(unsigned char* dst, int dw, int dh, int dx, int dy,
                            const unsigned char* src, int sw, int sh)
{
    if (!dst || !src || dw <= 0 || dh <= 0) return;
    for (int y = 0; y < sh; ++y)
    {
        const int ty = dy + y;
        if (ty < 0 || ty >= dh) continue;
        for (int x = 0; x < sw; ++x)
        {
            const int tx = dx + x;
            if (tx < 0 || tx >= dw) continue;
            const unsigned char* s = src + ((size_t)y * sw + x) * 4;
            if (!s[3]) continue;
            unsigned char* d = dst + ((size_t)ty * dw + tx) * 4;
            d[0] = s[0]; d[1] = s[1]; d[2] = s[2]; d[3] = s[3];
        }
    }
}

/* same, but the source is stored bottom-up (glDrawPixels order) */
static void OvCwCopyBottomUp(unsigned char* dst, int dw, int dh, int dx, int dy,
                             const unsigned char* src, int sw, int sh)
{
    if (!dst || !src || dw <= 0 || dh <= 0) return;
    for (int y = 0; y < sh; ++y)
    {
        const int ty = dy + y;
        if (ty < 0 || ty >= dh) continue;
        const unsigned char* row = src + (size_t)(sh - 1 - y) * sw * 4;
        for (int x = 0; x < sw; ++x)
        {
            const int tx = dx + x;
            if (tx < 0 || tx >= dw) continue;
            const unsigned char* s = row + (size_t)x * 4;
            if (!s[3]) continue;
            unsigned char* d = dst + ((size_t)ty * dw + tx) * 4;
            d[0] = s[0]; d[1] = s[1]; d[2] = s[2]; d[3] = s[3];
        }
    }
}

static void OvTogglePanelFromWindow(void);

extern "C" void DdhOverlayToggle(void);
extern "C" void DdhOverlaySetHtml(const char* html);
extern "C" void DdhOverlayCursorSet(int over);
extern "C" void DdhOverlayRequestButtonClick(void);
extern "C" void DdhOverlayRequestCursor(int over);

static void OvTogglePanelFromWindow(void)
{
    /* KK 式覆盖层：按钮和固定 HTML 页面由同一个系统合成窗口承载。 */
    if (g_htmlPath[0]) DdhOverlaySetHtml(g_htmlPath);
    DdhOverlayToggle();
}
/* The composed window takes the clicks itself. Relying on the game's window
   procedure to forward them is not reliable (War3 restores its own WndProc and
   in mouse-lock mode synthesises coordinates), which is exactly why clicking
   the button did nothing. */
static LRESULT CALLBACK OvCwProc(HWND h, UINT msg, WPARAM wp, LPARAM lp)
{
    switch (msg)
    {
    case WM_MOUSEACTIVATE:
        return MA_NOACTIVATE;              /* never steal focus from the game */
    case WM_SETCURSOR:
        SetCursor(LoadCursorW(NULL, (LPCWSTR)IDC_ARROW));
        return TRUE;
    case WM_MOUSEMOVE:
    {
        if (!g_ovCwTracking)
        {
            TRACKMOUSEEVENT tme;
            memset(&tme, 0, sizeof(tme));
            tme.cbSize = sizeof(tme);
            tme.dwFlags = TME_LEAVE;
            tme.hwndTrack = h;
            g_ovCwTracking = TrackMouseEvent(&tme) ? 1 : 0;
        }
        POINT pt = { (int)(short)LOWORD(lp), (int)(short)HIWORD(lp) };
        RECT b = g_ovCwLocalBtn, p = g_ovCwLocalPanel;
        const int over =
            (pt.x >= b.left && pt.x < b.right && pt.y >= b.top && pt.y < b.bottom) ||
            (g_ovPanelVisible && pt.x >= p.left && pt.x < p.right &&
             pt.y >= p.top && pt.y < p.bottom);
        DdhOverlayRequestCursor(over);
        break;
    }
    case WM_MOUSELEAVE:
        g_ovCwTracking = 0;
        DdhOverlayRequestCursor(0);
        break;
    case WM_LBUTTONUP:
    {
        POINT pt = { (int)(short)LOWORD(lp), (int)(short)HIWORD(lp) };
        RECT b = g_ovCwLocalBtn;
        if (pt.x >= b.left && pt.x < b.right && pt.y >= b.top && pt.y < b.bottom)
        {
            OvTogglePanelFromWindow();
            return 0;
        }
        return 0;
    }

    default:
        break;
    }
    return DefWindowProcA(h, msg, wp, lp);
}
static int OvCwEnsure(int w, int h)
{
    if (g_ovCw && g_ovCwW == w && g_ovCwH == h) return 1;
    if (g_ovCwBmp) { DeleteObject(g_ovCwBmp); g_ovCwBmp = NULL; g_ovCwBits = NULL; }
    if (g_ovCwMem) { DeleteDC(g_ovCwMem); g_ovCwMem = NULL; }
    if (g_ovCwScreen) { ReleaseDC(NULL, g_ovCwScreen); g_ovCwScreen = NULL; }
    if (g_ovCw) { DestroyWindow(g_ovCw); g_ovCw = NULL; g_ovCwShown = 0; }

    WNDCLASSA wc;
    memset(&wc, 0, sizeof(wc));
    wc.lpfnWndProc = OvCwProc;
    wc.hInstance = GetModuleHandleA(NULL);
    wc.lpszClassName = "DdhOverlayComposeWnd";
    wc.hCursor = LoadCursorW(NULL, (LPCWSTR)IDC_ARROW);
    RegisterClassA(&wc);

    g_ovCw = CreateWindowExA(
        WS_EX_LAYERED | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE,
        "DdhOverlayComposeWnd", "", WS_POPUP,
        0, 0, w, h, g_ovWnd, NULL, wc.hInstance, NULL);
    if (!g_ovCw) { OvLog("compose window failed err=%lu", GetLastError()); return 0; }

    g_ovCwScreen = GetDC(NULL);
    g_ovCwMem = CreateCompatibleDC(g_ovCwScreen);
    BITMAPINFO bmi;
    memset(&bmi, 0, sizeof(bmi));
    bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bmi.bmiHeader.biWidth = w;
    bmi.bmiHeader.biHeight = -h;
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = BI_RGB;
    g_ovCwBmp = CreateDIBSection(g_ovCwMem, &bmi, DIB_RGB_COLORS, &g_ovCwBits, NULL, 0);
    if (!g_ovCwBmp || !g_ovCwBits) { OvLog("compose dib failed"); return 0; }
    SelectObject(g_ovCwMem, g_ovCwBmp);
    g_ovCwW = w; g_ovCwH = h;
    OvLog("compose overlay window %dx%d", w, h);
    return 1;
}

static void OvCwHide(void)
{
    if (g_ovCw && g_ovCwShown) { ShowWindow(g_ovCw, SW_HIDE); g_ovCwShown = 0; }
}

/* keep exactly our own ShowCursor() increments so leaving the overlay restores
   the game's hidden-cursor state (ShowCursor is a counted toggle) */
static int s_ovCursorDelta = 0;
static int s_ovCursorOver = -1;
static void OvCursorOverSet(int over)
{
    static DWORD s_last = 0;
    const DWORD now = GetTickCount();

    if (!over)
    {
        if (s_ovCursorOver != 0)
        {
            while (s_ovCursorDelta > 0) { ShowCursor(FALSE); --s_ovCursorDelta; }
            s_ovCursorOver = 0;
            OvLog("system cursor restored (delta=%d)", s_ovCursorDelta);
        }
        return;
    }

    /* the game may keep pushing the display count back down, so re-assert
       periodically instead of only on the transition */
    if (s_ovCursorOver == 1 && (DWORD)(now - s_last) < 400) return;
    s_last = now;
    s_ovCursorOver = 1;
    const int before = s_ovCursorDelta;
    while (s_ovCursorDelta < 6)
    {
        const int c = ShowCursor(TRUE);
        ++s_ovCursorDelta;
        if (c >= 0) break;
    }
    SetCursor(LoadCursorW(NULL, (LPCWSTR)IDC_ARROW));
    if (before != s_ovCursorDelta)
        OvLog("system cursor shown over overlay (delta=%d)", s_ovCursorDelta);
}

/* rebuild the composed image and push it to the window */
static void OvCwUpdate(int cw, int ch, int bx0, int by0, int bx1, int by1)
{
    if (!g_ovWnd) return;
    g_ovCwFrameReady = 0;

    const int btnW = bx1 - bx0, btnH = by1 - by0;
    const int panW = OV_HTML_W, panH = OV_HTML_H;
    const int panX = bx1 - panW;
    const int panY = by1 + OV_PANEL_GAP;

    int winX = bx0, winY = by0, winW = btnW, winH = btnH;
    if (g_ovPanelVisible && panH > 40)
    {
        const int l = min(winX, panX);
        const int t = min(winY, panY);
        const int r = max(bx1, panX + panW);
        const int b = max(by1, panY + panH);
        winX = l; winY = t; winW = r - l; winH = b - t;
    }
    if (winW <= 0 || winH <= 0) return;
    if (!OvCwEnsure(winW, winH)) return;

    unsigned char* dst = (unsigned char*)g_ovCwBits;
    memset(dst, 0, (size_t)winW * winH * 4);

    const int btnOffX = bx0 - winX, btnOffY = by0 - winY;
    g_ovCwLocalBtn.left = btnOffX; g_ovCwLocalBtn.top = btnOffY;
    g_ovCwLocalBtn.right = btnOffX + btnW; g_ovCwLocalBtn.bottom = btnOffY + btnH;
    if (g_ovPanelVisible && panH > 40)
    {
        g_ovCwLocalPanel.left = panX - winX; g_ovCwLocalPanel.top = panY - winY;
        g_ovCwLocalPanel.right = g_ovCwLocalPanel.left + panW;
        g_ovCwLocalPanel.bottom = g_ovCwLocalPanel.top + panH;
    }
    else
    {
        g_ovCwLocalPanel.left = g_ovCwLocalPanel.right = 0;
    }

    if (g_ovPanelVisible && panH > 40)
    {
        if (OvStaticHtmlRefresh())
        {
            OvCwCopyTopDown(dst, winW, winH, panX - winX, panY - winY,
                            g_staticHtmlPixels, g_staticHtmlW, g_staticHtmlH);
        }
        else if (OvHtmlRefresh())
        {
            const int hw = *(const int*)(g_htmlView + 4);
            const int hh = *(const int*)(g_htmlView + 8);
            OvCwCopyTopDown(dst, winW, winH, panX - winX, panY - winY,
                            g_htmlView + OV_HTML_HDR, hw, hh);
        }
    }

    if (g_ovBtnVisible)
    {
        if (!s_btnArtReady) OvBuildButtonArt();
        /* the button art is opaque: copy it without the alpha test */
        for (int y = 0; y < OV_BTN_H; ++y)
        {
            const int ty = btnOffY + y;
            if (ty < 0 || ty >= winH) continue;
            const unsigned char* row = s_btnArt + (size_t)(OV_BTN_H - 1 - y) * OV_BTN_W * 4;
            for (int x = 0; x < OV_BTN_W; ++x)
            {
                const int tx = btnOffX + x;
                if (tx < 0 || tx >= winW) continue;
                const unsigned char* s = row + (size_t)x * 4;
                unsigned char* d = dst + ((size_t)ty * winW + tx) * 4;
                d[0] = s[0]; d[1] = s[1]; d[2] = s[2]; d[3] = 255;
            }
        }
    }

    g_ovCwFrameX = winX;
    g_ovCwFrameY = winY;
    g_ovCwFrameW = winW;
    g_ovCwFrameH = winH;
    g_ovCwFrameReady = 1;

    /* KK-style path: the composed image is drawn into the game's own GL frame
       before CCursorFrame::OnLayerUpdate calls the original cursor renderer.
       The actual War3 cursor is therefore painted last, exactly as in the
       platform shop/settings overlay. */
    if (OvUseGameLayer())
    {
        OvCwHide();
        return;
    }

    POINT ptDst = { winX, winY };
    if (!ClientToScreen(g_ovWnd, &ptDst)) return;
    SIZE size = { winW, winH };
    POINT ptSrc = { 0, 0 };
    BLENDFUNCTION bf;
    bf.BlendOp = AC_SRC_OVER;
    bf.BlendFlags = 0;
    bf.SourceConstantAlpha = 255;
    bf.AlphaFormat = AC_SRC_ALPHA;
    if (!UpdateLayeredWindow(g_ovCw, g_ovCwScreen, &ptDst, &size, g_ovCwMem, &ptSrc, 0, &bf, ULW_ALPHA))
    {
        static int once = 0;
        if (!once) { once = 1; OvLog("compose UpdateLayeredWindow failed err=%lu", GetLastError()); }
        return;
    }
    if (!g_ovCwShown)
    {
        ShowWindow(g_ovCw, SW_SHOWNOACTIVATE);
        SetWindowPos(g_ovCw, HWND_TOP, 0, 0, 0, 0,
                     SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
        g_ovCwShown = 1;
        OvLog("compose overlay shown");
    }
}

static int s_ovLwPushedThisFrame = 0;

static void OvPaintContent(int cw, int ch, int bx0, int by0, int bx1, int by1)
{
    if (g_ovProbeMode)
    {
        /* A: scissor+clear (known good after the glClear rewrite) */
        OvFillRectGl(20, 20, 40, 40, ch, 1.0f, 0.10f, 0.85f, 1.0f);
        /* B: immediate-mode quad (was silently swallowed before) */
        glDisable(GL_TEXTURE_2D);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glColor4f(0.10f, 1.0f, 0.20f, 1.0f);
        glBegin(GL_QUADS);
        glVertex2i(80, 20); glVertex2i(120, 20); glVertex2i(120, 60); glVertex2i(80, 60);
        glEnd();
        /* C: glDrawPixels (the path the WebView2 bitmap would take) */
        static unsigned char s_probe[64 * 64 * 4];
        static int s_probeReady = 0;
        if (!s_probeReady)
        {
            s_probeReady = 1;
            for (int y = 0; y < 64; ++y)
                for (int x = 0; x < 64; ++x)
                {
                    unsigned char* p = &s_probe[(y * 64 + x) * 4];
                    p[0] = (unsigned char)(x * 4);        /* B */
                    p[1] = (unsigned char)(y * 4);        /* G */
                    p[2] = 255;                           /* R */
                    p[3] = 255;
                }
        }
        glDisable(GL_BLEND);
        glDisable(GL_ALPHA_TEST);
        glDisable(GL_TEXTURE_2D);
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
        glPixelStorei(GL_UNPACK_SKIP_ROWS, 0);
        glPixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
        glRasterPos2i(140, 84);       /* y down: this is the bottom-left corner */
        glDrawPixels(64, 64, GL_BGRA, GL_UNSIGNED_BYTE, s_probe);
        glEnable(GL_BLEND);
        return;
    }

    if (g_ovTestFill)
    {
        OvFillRectGl(0, 0, cw, ch, ch, 1.0f, 0.10f, 0.85f, 1.0f);
        return;
    }
    /* panel rectangle (kept for hit testing even though the panel is a window) */
    if (g_ovPanelVisible)
    {
        int pw = OV_HTML_W, ph = OV_HTML_H;
        int px0 = bx1 - pw, py0 = by1 + OV_PANEL_GAP;
        if (px0 < 4) px0 = 4;
        if (py0 + ph > ch - 4) ph = ch - 4 - py0;
        if (ph > 40)
        {
            g_ovPanelRect.left = px0; g_ovPanelRect.top = py0;
            g_ovPanelRect.right = px0 + pw; g_ovPanelRect.bottom = py0 + ph;
        }
        else
        {
            g_ovPanelRect.left = g_ovPanelRect.right = 0;
        }
    }
    else
    {
        g_ovPanelRect.left = g_ovPanelRect.right = 0;
    }

    if (g_ovBtnVisible || g_ovPanelVisible)
    {
        if (!s_ovLwPushedThisFrame)
        {
            s_ovLwPushedThisFrame = 1;
            OvCwUpdate(cw, ch, bx0, by0, bx1, by1);
            if (OvUseGameLayer() && g_ovCwFrameReady && g_ovCwBits)
            {
                glDisable(GL_TEXTURE_2D);
                glEnable(GL_BLEND);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                glDisable(GL_ALPHA_TEST);
                const int ok = OvBlitTopDown(g_ovCwFrameX, g_ovCwFrameY,
                                             g_ovCwFrameW, g_ovCwFrameH,
                                             cw, ch,
                                             (const unsigned char*)g_ovCwBits);
                if (ok) InterlockedIncrement(&g_ovGameLayerFrames);
            }
        }
    }
    else
    {
        OvCwHide();
    }
}

static void OvDraw(HDC hdc)
{
    if (!g_ovBtnVisible && !g_ovPanelVisible) return;

    HGLRC ctx = wglGetCurrentContext();
    if (!ctx) return;
    if (ctx != g_ovCtx)
    {
        g_ovCtx = ctx;
        g_ovTex = 0;                       /* textures die with the context */
        OvLog("GL context %p (thread %lu)", (void*)ctx, (unsigned long)GetCurrentThreadId());
    }

    HWND wnd = OvGameWindow(hdc);
    RECT rc = { 0, 0, 0, 0 };
    if (!wnd || !GetClientRect(wnd, &rc)) return;
    const int cw = rc.right - rc.left, ch = rc.bottom - rc.top;
    if (cw < 64 || ch < 64) return;

    const int bx1 = cw - OV_BTN_MARGIN_R;
    const int by0 = OV_BTN_MARGIN_T;
    const int bx0 = bx1 - OV_BTN_W;
    const int by1 = by0 + OV_BTN_H;
    g_ovRect.left = bx0; g_ovRect.top = by0; g_ovRect.right = bx1; g_ovRect.bottom = by1;

    GLint vp[4] = { 0, 0, 0, 0 };
    glGetIntegerv(GL_VIEWPORT, vp);

    s_ovLwPushedThisFrame = 0;
    const LONG frame = InterlockedIncrement(&g_ovFrames);
    if (frame == 1)
        OvLog("first overlay frame: client=%dx%d viewport=%d,%d %dx%d ctx=%p",
              cw, ch, vp[0], vp[1], vp[2], vp[3], (void*)ctx);

    /* Window-only mode: the overlay lives in layered windows, so we must not
       touch a single GL state here. Doing so (even without drawing) is what
       turned the game's screen black. */
    if (!g_ovUseGl)
    {
        s_ovLwPushedThisFrame = 0;
        OvPaintContent(cw, ch, bx0, by0, bx1, by1);
        return;
    }
    else if ((frame % 600) == 0)
        OvLog("overlay heartbeat: frames=%ld panel=%ld client=%dx%d",
              (long)frame, (long)g_ovPanelVisible, cw, ch);

    /* If the game left an offscreen framebuffer bound while presenting, drawing
       into it would never reach the window (and the readback would show the
       untouched window buffer). Force the default framebuffer while we draw. */
    GLint dfb = 0, rfb = 0;
    glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &dfb);
    glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &rfb);
    if (frame <= 10)
    {
        GLint dbuf = 0, rbuf = 0, drb = 0;
        glGetIntegerv(GL_DOUBLEBUFFER, &dbuf);
        glGetIntegerv(GL_READ_BUFFER, &rbuf);
        glGetIntegerv(GL_DRAW_BUFFER, &drb);
        OvLog("f%ld ctx=%p drawFb=%d readFb=%d double=%d readBuf=0x%X drawBuf=0x%X err=%04X",
              (long)frame, (void*)ctx, (int)dfb, (int)rfb, (int)dbuf, (int)rbuf, (int)drb,
              (unsigned)glGetError());
        if (frame == 1)
        {
            const char* ver = (const char*)glGetString(GL_VERSION);
            const char* ren = (const char*)glGetString(GL_RENDERER);
            OvLog("GL version=%s renderer=%s", ver ? ver : "?", ren ? ren : "?");
        }
    }
    const int switchedFb = (dfb != 0 || rfb != 0) && OvBindFb() != NULL;
    if (switchedFb)
    {
        OvBindFb()(GL_DRAW_FRAMEBUFFER, 0);
        OvBindFb()(GL_READ_FRAMEBUFFER, 0);
    }

    /* the game may leave the draw buffer pointed at GL_FRONT / GL_NONE, a
       disabled colour mask or a live rasterizer discard: none of that is
       restored by glPushAttrib in a way that helps us draw, so set it here. */
    glDrawBuffer(GL_BACK);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glDisable(GL_LOGIC_OP);
#ifdef GL_COLOR_LOGIC_OP
    glDisable(GL_COLOR_LOGIC_OP);
#endif
    glDisable(0x8C89);            /* GL_RASTERIZER_DISCARD, invalid enum on GL<3 (harmless) */
    /* ARB/NV vertex+ fragment programs are NOT covered by glUseProgram(0) and
       they own the vertex pipeline: with one bound, immediate-mode vertices go
       through the program and the quad silently disappears. War3's GL renderer
       is from the ARB_vertex_program era, so this matters. */
    glDisable(0x8620);            /* GL_VERTEX_PROGRAM_ARB / _NV */
    glDisable(0x8804);            /* GL_FRAGMENT_PROGRAM_ARB */
    glDisable(0x8642);            /* GL_VERTEX_PROGRAM_TWO_SIDE_ARB */
    /* user clip planes invalidate the raster position (rasterValid=0 makes
       glDrawPixels a silent no-op); the game may leave some enabled */
    for (int cp = 0; cp < 6; ++cp) glDisable(GL_CLIP_PLANE0 + cp);
    (void)glGetError();           /* clear the error an unsupported enum may have set */

    glPushAttrib(GL_ALL_ATTRIB_BITS);
    glPushClientAttrib(GL_CLIENT_ALL_ATTRIB_BITS);   /* array enables + pointers */
    glMatrixMode(GL_TEXTURE); glPushMatrix(); glLoadIdentity();
    glMatrixMode(GL_PROJECTION); glPushMatrix(); glLoadIdentity();
    glMatrixMode(GL_MODELVIEW); glPushMatrix(); glLoadIdentity();

    /* The game draws with client arrays. glPushAttrib does NOT save client
       state, so every array we switch off must be switched back on exactly as
       it was -- otherwise the game's next vertices come from a stale pointer
       and the whole screen goes black (that regression was real). */
    const GLboolean vaOn = glIsEnabled(GL_VERTEX_ARRAY);
    const GLboolean taOn = glIsEnabled(GL_TEXTURE_COORD_ARRAY);
    const GLboolean caOn = glIsEnabled(GL_COLOR_ARRAY);
    const GLboolean naOn = glIsEnabled(GL_NORMAL_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_NORMAL_ARRAY);

    glViewport(0, 0, cw, ch);
    /* the ortho must land on the PROJECTION matrix: calling glOrtho while
       MODELVIEW is current (as an earlier version did) leaves the projection
       at identity and the quad is simply clipped away -- nothing is drawn. */
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0.0, (double)cw, (double)ch, 0.0, -1.0, 1.0);   /* y down, top-left origin */
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    glDisable(GL_LIGHTING);
    glDisable(GL_FOG);
    glDisable(GL_ALPHA_TEST);
    glDisable(GL_SCISSOR_TEST);
    glDisable(GL_STENCIL_TEST);
    glDisable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glShadeModel(GL_FLAT);
    (void)glGetError();                 /* clear anything the game left behind */

    /* unbind the game's program/VAO so our immediate-mode quad is transformed
       by the fixed pipeline (see OvUseProgram) */
    fn_use_program_t up = OvUseProgram();
    GLint prevProg = 0;
    if (up)
    {
        glGetIntegerv(0x8B8D /*GL_CURRENT_PROGRAM*/, &prevProg);
        if (prevProg) up(0);
    }
    fn_bind_vao_t bv = OvBindVao();
    GLint prevVao = 0;
    if (bv)
    {
        glGetIntegerv(0x85B5 /*GL_VERTEX_ARRAY_BINDING*/, &prevVao);
        if (prevVao) bv(0);
    }
    if (frame <= 8)
        OvLog("f%ld prevProgram=%d prevVao=%d", (long)frame, (int)prevProg, (int)prevVao);
    if (frame <= 8)
    {
        GLint prof = 0;
        glGetIntegerv(0x9126 /*GL_CONTEXT_PROFILE_MASK*/, &prof);
        OvLog("f%ld profileMask=0x%X (compat=0x2 core=0x1)", (long)frame, (unsigned)prof);
    }

    /* Paint into the back buffer and into the front buffer: which one is
       actually scanned out depends on War3's present path and could not be
       determined from the outside, and a 30x30 clear is cheap. */
    GLint drbSave = GL_BACK;
    glGetIntegerv(GL_DRAW_BUFFER, &drbSave);
    glDrawBuffer(GL_BACK);
    OvPaintContent(cw, ch, bx0, by0, bx1, by1);
    glDrawBuffer(GL_FRONT);
    OvPaintContent(cw, ch, bx0, by0, bx1, by1);
    glDrawBuffer((GLenum)drbSave);

    /* restore whatever the game had bound */
    if (bv && prevVao > 0) bv((GLuint)prevVao);
    if (up && prevProg > 0) up((GLuint)prevProg);

    glMatrixMode(GL_MODELVIEW); glPopMatrix();
    glMatrixMode(GL_PROJECTION); glPopMatrix();
    glMatrixMode(GL_TEXTURE); glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
    glPopClientAttrib();          /* restores the client arrays byte for byte */
    glPopAttrib();

    if (frame <= 8)
    {
        const GLenum e = glGetError();
        OvLog("f%ld draw finished, glGetError=0x%04X", (long)frame, (unsigned)e);
    }

    /* prove it without depending on screen capture: read the button centre back
       from both buffers. Only a hit lets ddh.cpp hide its engine-frame button. */
    if (frame <= 8 || (frame % 300) == 0)
    {
        unsigned char pb[4] = { 0, 0, 0, 0 };
        unsigned char pf[4] = { 0, 0, 0, 0 };
        glPushAttrib(GL_PIXEL_MODE_BIT | GL_COLOR_BUFFER_BIT);
        glPixelStorei(GL_PACK_ALIGNMENT, 1);
        glReadBuffer(GL_BACK);
        glReadPixels(bx0 + 1, ch - (by0 + 1), 1, 1, GL_BGRA, GL_UNSIGNED_BYTE, pb);
        glReadBuffer(GL_FRONT);
        glReadPixels(bx0 + 1, ch - (by0 + 1), 1, 1, GL_BGRA, GL_UNSIGNED_BYTE, pf);
        glPopAttrib();

        /* the button's gold plate: 0.84/0.67/0.29 -> R214 G171 B74 */
        const int magB = (pb[2] > 170 && pb[1] > 120 && pb[0] < 130);
        const int magF = (pf[2] > 170 && pf[1] > 120 && pf[0] < 130);
        if ((magB || magF) && InterlockedExchange(&g_ovProven, 1) == 0)
            OvLog("PROVEN: back=%d front=%d", magB, magF);
        if (frame <= 8)
            OvLog("f%ld probe back=%u,%u,%u front=%u,%u,%u proven=%ld",
                  (long)frame, pb[2], pb[1], pb[0], pf[2], pf[1], pf[0], (long)g_ovProven);
    }

    /* restore the client-array enables exactly (see above) */
    if (vaOn) glEnableClientState(GL_VERTEX_ARRAY);
    if (taOn) glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    if (caOn) glEnableClientState(GL_COLOR_ARRAY);
    if (naOn) glEnableClientState(GL_NORMAL_ARRAY);

    if (switchedFb)
    {
        OvBindFb()(GL_DRAW_FRAMEBUFFER, (GLuint)dfb);
        OvBindFb()(GL_READ_FRAMEBUFFER, (GLuint)rfb);
    }

    OvMaybeDumpFrame(cw, ch);
}

/* ------------------------------------------------ on-demand frame capture
   Screen capture of a fullscreen GL window is unreliable (DWM occlusion, the
   window may be behind another app), so the overlay dumps its own back buffer
   when the trigger file C:\launch\ddh-ovdump.on appears. The dump is written as
   a 32-bit bottom-up BMP (glReadPixels row order == BMP row order). */
static void OvWriteBmp(const char* path, const unsigned char* buf, int cw, int ch)
{
    BITMAPFILEHEADER fh;
    BITMAPINFOHEADER ih;
    memset(&fh, 0, sizeof(fh));
    memset(&ih, 0, sizeof(ih));
    ih.biSize = sizeof(ih);
    ih.biWidth = cw;
    ih.biHeight = ch;
    ih.biPlanes = 1;
    ih.biBitCount = 32;
    ih.biCompression = BI_RGB;
    ih.biSizeImage = (DWORD)((size_t)cw * ch * 4);
    fh.bfType = 0x4D42;
    fh.bfOffBits = (DWORD)(sizeof(fh) + sizeof(ih));
    fh.bfSize = fh.bfOffBits + ih.biSizeImage;

    FILE* f = NULL;
    if (fopen_s(&f, path, "wb") == 0 && f)
    {
        fwrite(&fh, sizeof(fh), 1, f);
        fwrite(&ih, sizeof(ih), 1, f);
        fwrite(buf, ih.biSizeImage, 1, f);
        fclose(f);
        OvLog("dumped %dx%d -> %s", cw, ch, path);
    }
    else
    {
        OvLog("dump: cannot write %s", path);
    }
}

static void OvMaybeDumpFrame(int cw, int ch)
{
    static int s_tick = 0;
    if ((++s_tick % 20) != 0) return;
    const char* trig = "C:\\launch\\ddh-ovdump.on";
    if (GetFileAttributesA(trig) == INVALID_FILE_ATTRIBUTES) return;
    DeleteFileA(trig);

    static unsigned char* buf = NULL;
    static size_t bufSize = 0;
    const size_t need = (size_t)cw * (size_t)ch * 4;
    if (!buf || bufSize < need)
    {
        if (buf) free(buf);
        buf = (unsigned char*)malloc(need);
        bufSize = buf ? need : 0;
        if (!buf) { OvLog("dump: malloc %u failed", (unsigned)need); return; }
    }

    glPushAttrib(GL_PIXEL_MODE_BIT | GL_COLOR_BUFFER_BIT);
    GLint rfbDump = 0;
    glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &rfbDump);
    const int fbSwitched = (rfbDump != 0) && OvBindFb() != NULL;
    if (fbSwitched) OvBindFb()(GL_READ_FRAMEBUFFER, 0);
    glPixelStorei(GL_PACK_ALIGNMENT, 1);

    glReadBuffer(GL_BACK);
    glReadPixels(0, 0, cw, ch, GL_BGRA, GL_UNSIGNED_BYTE, buf);
    OvWriteBmp("C:\\launch\\ddh-ovdump.bmp", buf, cw, ch);

    glReadBuffer(GL_FRONT);
    glReadPixels(0, 0, cw, ch, GL_BGRA, GL_UNSIGNED_BYTE, buf);
    OvWriteBmp("C:\\launch\\ddh-ovdump-front.bmp", buf, cw, ch);

    if (fbSwitched) OvBindFb()(GL_READ_FRAMEBUFFER, (GLuint)rfbDump);
    glPopAttrib();
}

static volatile LONG g_ovStopPatch = 0;

/* ------------------------------------------------------------------ hooks */
/* one draw per present: opengl32!wglSwapBuffers/wglSwapLayerBuffers internally
   call gdi32!SwapBuffers, which is patched too, so without this guard every
   frame would be drawn twice (and the inner draw happens inside the driver). */
static __declspec(thread) LONG t_ovInPresent = 0;

static void OvOnPresent(HDC hdc)
{
    /* In the cursor-layer path the overlay is already drawn before the game's
       real cursor and is waiting in the back buffer. Drawing again at present
       would put it back above the cursor. */
    if (OvUseGameLayer()) return;
    if (t_ovInPresent) return;
    t_ovInPresent = 1;
    __try { OvDraw(hdc); }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        if (InterlockedIncrement(&g_ovLogCount) <= 5)
            OvLog("draw raised code=%08X (swallowed)", (unsigned)GetExceptionCode());
    }
    t_ovInPresent = 0;
}

static BOOL WINAPI OvHookSwap(HDC hdc)
{
    OvOnPresent(hdc);
    ++t_ovInPresent;
    BOOL r = g_ovOrigSwap ? g_ovOrigSwap(hdc) : FALSE;
    --t_ovInPresent;
    return r;
}

static BOOL WINAPI OvHookWglSwap(HDC hdc)
{
    OvOnPresent(hdc);
    ++t_ovInPresent;
    BOOL r = g_ovOrigWglSwap ? g_ovOrigWglSwap(hdc) : FALSE;
    --t_ovInPresent;
    return r;
}

/* War3 1.27's real present call */
static BOOL WINAPI OvHookWglSwapLayers(HDC hdc, UINT planes)
{
    OvOnPresent(hdc);
    ++t_ovInPresent;
    BOOL r = g_ovOrigWglLayers ? g_ovOrigWglLayers(hdc, planes) : FALSE;
    --t_ovInPresent;
    return r;
}

/* KK's War3Plugin hooks CCursorFrame::OnLayerUpdate (War3 1.27 RVA 0xC97D0,
   recovered from its version table). We hook +0xC97D7, after the first 7-byte
   prologue. KK's entry detour runs first; its trampoline enters our hook; we
   draw the settlement page; then the remaining original function paints the
   selected War3 cursor last. This preserves KK's hook and the desired order:
   KK shop < settlement page < real War3 cursor. */
static BOOL __fastcall OvHookCursorLayerUpdate(void* self, int edx,
                                               int a1, int a2, int a3)
{
    if (OvUseGameLayer())
    {
        __try
        {
            HDC hdc = wglGetCurrentDC();
            if (hdc) OvDraw(hdc);
        }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            if (InterlockedIncrement(&g_ovLogCount) <= 5)
                OvLog("cursor-layer draw raised %08X (swallowed)",
                      (unsigned)GetExceptionCode());
        }
    }
    return g_ovOrigCursorLayerUpdate
        ? g_ovOrigCursorLayerUpdate(self, edx, a1, a2, a3)
        : FALSE;
}

static int OvSuspendOtherThreads(HANDLE* handles, int capacity)
{
    int count = 0;
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    if (snap == INVALID_HANDLE_VALUE) return 0;

    const DWORD selfPid = GetCurrentProcessId();
    const DWORD selfTid = GetCurrentThreadId();
    THREADENTRY32 te;
    memset(&te, 0, sizeof(te));
    te.dwSize = sizeof(te);
    if (Thread32First(snap, &te))
    {
        do
        {
            if (te.th32OwnerProcessID != selfPid || te.th32ThreadID == selfTid) continue;
            if (count >= capacity) break;
            HANDLE thread = OpenThread(THREAD_SUSPEND_RESUME, FALSE, te.th32ThreadID);
            if (!thread) continue;
            if (SuspendThread(thread) == (DWORD)-1)
            {
                CloseHandle(thread);
                continue;
            }
            handles[count++] = thread;
        } while (Thread32Next(snap, &te));
    }
    CloseHandle(snap);
    return count;
}

static void OvResumeThreads(HANDLE* handles, int count)
{
    for (int i = count - 1; i >= 0; --i)
    {
        if (!handles[i]) continue;
        ResumeThread(handles[i]);
        CloseHandle(handles[i]);
        handles[i] = NULL;
    }
}

static void OvPatchCursorLayerUpdate(void)
{
    if (InterlockedCompareExchange(&g_ovCursorHookDone, 0, 0) != 0) return;

    HMODULE game = GetModuleHandleA("game.dll");
    if (!game) return;

    uint8_t* fn = (uint8_t*)game + 0xC97D7u;
    HANDLE suspended[256] = { 0 };
    int suspendedCount = 0;
    __try
    {
        if (fn[0] != 0xE8)
        {
            OvLog("cursor-layer hook skipped: expected call at game+0xC97D7, found %02X %02X %02X %02X %02X",
                  fn[0], fn[1], fn[2], fn[3], fn[4]);
            InterlockedExchange(&g_ovCursorHookDone, 2);
            return;
        }

        uint8_t* tramp = (uint8_t*)VirtualAlloc(NULL, 32, MEM_COMMIT | MEM_RESERVE,
                                                PAGE_EXECUTE_READWRITE);
        if (!tramp)
        {
            OvLog("cursor-layer trampoline failed err=%lu", GetLastError());
            InterlockedExchange(&g_ovCursorHookDone, 2);
            return;
        }

        /* Relocate the original E8 rel32 call, then jump back to game+0xC97DC. */
        const int32_t oldRel = *(int32_t*)(fn + 1);
        uint8_t* callTarget = fn + 5 + oldRel;
        tramp[0] = 0xE8;
        *(int32_t*)(tramp + 1) = (int32_t)(callTarget - (tramp + 5));
        tramp[5] = 0xE9;
        *(int32_t*)(tramp + 6) = (int32_t)((fn + 5) - (tramp + 10));

        DWORD oldProt = 0;
        if (!VirtualProtect(fn, 5, PAGE_EXECUTE_READWRITE, &oldProt))
        {
            VirtualFree(tramp, 0, MEM_RELEASE);
            OvLog("cursor-layer VirtualProtect failed err=%lu", GetLastError());
            InterlockedExchange(&g_ovCursorHookDone, 2);
            return;
        }

        g_ovOrigCursorLayerUpdate = (fn_cursor_layer_update_t)(uintptr_t)tramp;
        uint8_t patch[5] = { 0xE9, 0, 0, 0, 0 };
        *(int32_t*)(patch + 1) = (int32_t)((uint8_t*)&OvHookCursorLayerUpdate - (fn + 5));

        /* The engine has render/audio/network threads. Stop them only across the
           five-byte entry swap so nobody can execute a half-written jump. */
        suspendedCount = OvSuspendOtherThreads(suspended,
                                               (int)(sizeof(suspended) / sizeof(suspended[0])));
        memcpy(fn, patch, sizeof(patch));
        VirtualProtect(fn, 5, oldProt, &oldProt);
        FlushInstructionCache(GetCurrentProcess(), fn, 5);
        OvResumeThreads(suspended, suspendedCount);
        suspendedCount = 0;
        InterlockedExchange(&g_ovCursorHookDone, 1);
        OvLog("cursor-layer hook installed game+0xC97D7 trampoline=%p", tramp);
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        OvResumeThreads(suspended, suspendedCount);
        InterlockedExchange(&g_ovCursorHookDone, 2);
        OvLog("cursor-layer hook raised %08X", (unsigned)GetExceptionCode());
    }
}

static void OvPatchEverything(void)
{
    OvPatchAll("OPENGL32.dll", "wglSwapLayerBuffers", (void*)&OvHookWglSwapLayers, (void**)&g_ovOrigWglLayers);
    OvPatchAll("OPENGL32.dll", "wglSwapBuffers",      (void*)&OvHookWglSwap,      (void**)&g_ovOrigWglSwap);
    OvPatchAll("GDI32.dll",    "SwapBuffers",         (void*)&OvHookSwap,         (void**)&g_ovOrigSwap);
    if (g_ovUseGl) OvPatchCursorLayerUpdate();
}

/* game.dll (which owns the GL renderer) is loaded after us: keep re-scanning
   until the first overlay frame proves the present call is hooked */
static DWORD WINAPI OvPatchThread(LPVOID)
{
    for (int i = 0; i < 60 && !g_ovStopPatch; ++i)
    {
        Sleep(500);
        if (InterlockedCompareExchange(&g_ovFrames, 0, 0) > 0) break;
        ++g_ovPatchPass;
        OvPatchEverything();
    }
    if (InterlockedCompareExchange(&g_ovFrames, 0, 0) == 0)
        OvLog("patch thread gave up after %d passes; frames=0 (present call not found)",
              g_ovPatchPass);
    return 0;
}

/* -------------------------------------------------------------------- API */
extern "C" void DdhOverlayInit(HWND gameWnd)
{
    if (InterlockedCompareExchange(&g_ovInited, 1, 0) != 0) return;
    CreateDirectoryA(OV_SHARED_DIR, NULL);
    const char* marker = DdhOverlayMarkerText();
    OvLog("init: marker=%s wnd=%p pid=%lu", marker, (void*)gameWnd,
          (unsigned long)GetCurrentProcessId());
    if (!OvEnvOn("DDH_OVERLAY", 1)) { OvLog("disabled by DDH_OVERLAY"); return; }
    g_ovWnd = gameWnd;
    g_ovBtnVisible = OvEnvOn("DDH_OVERLAY_BUTTON", 1) ? 1 : 0;
    g_ovTestFill = OvEnvOn("DDH_OVERLAY_TESTFILL", 0);
    g_ovProbeMode = OvEnvOn("DDH_OVERLAY_PROBE", 0);
    g_ovDrawCursor = OvEnvOn("DDH_OVERLAY_DRAW_CURSOR", 0);
    g_ovUseGl = OvEnvOn("DDH_OVERLAY_GL", 0);
    g_ovForceOsCursor = OvEnvOn("DDH_OVERLAY_FORCE_OS_CURSOR", 0);
    if (OvEnvOn("DDH_OVERLAY_SHOW", 0)) g_ovPanelVisible = 1;
    OvPatchEverything();
    CreateThread(NULL, 0, OvPatchThread, NULL, 0, NULL);
    OvLog("init done: origWglLayers=%p origWglSwap=%p origSwap=%p",
          (void*)g_ovOrigWglLayers, (void*)g_ovOrigWglSwap, (void*)g_ovOrigSwap);
}

extern "C" int DdhOverlayHitTest(int x, int y)
{
    if (!g_ovBtnVisible) return 0;
    if (g_ovRect.right <= g_ovRect.left) return 0;
    return x >= g_ovRect.left && x < g_ovRect.right &&
           y >= g_ovRect.top  && y < g_ovRect.bottom;
}

extern "C" void DdhOverlayShowCursor(void);

extern "C" void DdhOverlayToggle(void)
{
    const DWORD now = GetTickCount();
    const DWORD last = (DWORD)InterlockedCompareExchange(&g_ovLastToggle, (LONG)now, 0);
    if (last && (DWORD)(now - last) < 150) return;
    InterlockedExchange(&g_ovLastToggle, (LONG)now);
    const LONG next = g_ovPanelVisible ? 0 : 1;
    InterlockedExchange(&g_ovPanelVisible, next);
    OvLog("toggle panel -> %ld (frames=%ld)", (long)next, (long)g_ovFrames);
}

extern "C" void DdhOverlayShow(int on)
{
    InterlockedExchange(&g_ovPanelVisible, on ? 1 : 0);
    OvLog("show panel %d", on ? 1 : 0);
}

extern "C" int DdhOverlayVisible(void) { return (int)g_ovPanelVisible; }
/* 1 only when a readback proved our pixels are in the presented frame; ddh.cpp
   keeps its engine-frame button until then, so the user always has a button. */
extern "C" int DdhOverlayProven(void) { return (int)g_ovProven; }
extern "C" int DdhOverlayReady(void)
{
    return (g_ovCwShown || InterlockedCompareExchange(&g_ovGameLayerFrames, 0, 0) > 0) ? 1 : 0;
}

/* 拖动/缩放游戏窗口时由游戏窗口过程立即调用；不能等下一次 swap。 */
extern "C" void DdhOverlaySyncPosition(void)
{
    if (!g_ovWnd || !g_ovCwShown) return;
    RECT rc = { 0, 0, 0, 0 };
    if (!GetClientRect(g_ovWnd, &rc)) return;
    const int cw = rc.right - rc.left;
    const int ch = rc.bottom - rc.top;
    if (cw < 64 || ch < 64) return;

    const int bx1 = cw - OV_BTN_MARGIN_R;
    const int by0 = OV_BTN_MARGIN_T;
    const int bx0 = bx1 - OV_BTN_W;
    const int by1 = by0 + OV_BTN_H;
    g_ovRect.left = bx0; g_ovRect.top = by0;
    g_ovRect.right = bx1; g_ovRect.bottom = by1;
    OvCwUpdate(cw, ch, bx0, by0, bx1, by1);
    static DWORD s_lastSyncLog = 0;
    const DWORD now = GetTickCount();
    if ((DWORD)(now - s_lastSyncLog) >= 500)
    {
        s_lastSyncLog = now;
        OvLog("position synced: client=%dx%d button=%d,%d..%d,%d",
              cw, ch, bx0, by0, bx1, by1);
    }
}

/* War3 paints its own software cursor inside the frame, so anything we draw
   covers it. The OS cursor is composited above every window, so the clean fix
   is to keep the system cursor visible while the pointer is over our pixels and
   let Windows draw it. Returns 1 when the pointer is over the button/panel. */
extern "C" int DdhOverlayCursorOver(void)
{
    if (!g_ovWnd) return 0;
    POINT p;
    if (!GetCursorPos(&p)) return 0;
    if (!ScreenToClient(g_ovWnd, &p)) return 0;
    RECT btn = g_ovRect, pan = g_ovPanelRect;
    btn.left -= OV_CUR_W; btn.top -= OV_CUR_H; btn.right += OV_CUR_W; btn.bottom += OV_CUR_H;
    pan.left -= OV_CUR_W; pan.top -= OV_CUR_H; pan.right += OV_CUR_W; pan.bottom += OV_CUR_H;
    if (OvPointInRect(btn, p.x, p.y)) return 1;
    if (g_ovPanelVisible && OvPointInRect(pan, p.x, p.y)) return 1;
    return 0;
}

/* make sure the hardware cursor is not hidden by the game */
extern "C" void DdhOverlayShowCursor(void)
{
    DdhOverlayCursorSet(1);
}

/* 引擎帧 UI 和窗口覆盖层共用同一个系统光标状态。只有 over 从 0->1 时
   ShowCursor 若干次，从 1->0 时按同样次数恢复，避免破坏游戏的引用计数。 */
extern "C" void DdhOverlayCursorSet(int over)
{
    OvCursorOverSet(over ? 1 : 0);
}
extern "C" void DdhOverlaySetMouseDown(int down) { g_ovMouseDown = down ? 1 : 0; }
extern "C" int  DdhOverlayMouseDown(void) { return (int)g_ovMouseDown; }
extern "C" int  DdhOverlayFrames(void) { return (int)g_ovFrames; }
