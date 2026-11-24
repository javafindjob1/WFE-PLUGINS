#include <windows.h>
#include <tlhelp32.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <GL/gl.h>

#include "third_party/imgui/imgui.h"
#include "third_party/imgui/backends/imgui_impl_win32.h"
#include "third_party/imgui/backends/imgui_impl_opengl3.h"
#include "third_party/detours/detours.h"

#ifndef GL_BGRA
#define GL_BGRA 0x80E1
#endif

extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(
    HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

typedef BOOL(__fastcall* fn_cursor_layer_update_t)(void*, int, int, int, int);
typedef void (APIENTRY* fn_bind_buffer_t)(GLenum, GLuint);
typedef void (APIENTRY* fn_use_program_t)(GLuint);
typedef void (APIENTRY* fn_bind_vao_t)(GLuint);
typedef void (APIENTRY* fn_active_texture_t)(GLenum);

extern "C" void DdhOverlaySetHtml(const char* html);
extern "C" void DdhOverlayRestartHtml(const char* html);
extern "C" const char* DdhOverlayMarkerText(void);
extern "C" int DdhOverlayEnsureHtmlMapping(void);
extern "C" int DdhWebUiAvailable(void);

#define DDH_PANEL_HTML_PATH "C:\\launch\\ddh_web\\dss.html"
#define DDH_PANEL_HEADER 64
#define DDH_PANEL_INPUT  64
#define DDH_PANEL_MAGIC  0x31484844
#define DDH_PANEL_MAX_W  1600
#define DDH_PANEL_MAX_H  1200

static fn_cursor_layer_update_t g_realCursorLayerUpdate = NULL;
static HWND    g_imguiGameWindow = NULL;
static bool    g_imguiReady = false;
static bool    g_imguiOpen = false;
static GLuint  g_panelTexture = 0;
static int     g_panelUploadLogs = 0;
static unsigned char* g_panelPixels = NULL;
static int     g_panelWidth = 0;
static int     g_panelHeight = 0;
static int     g_panelTextureWidth = 0;
static int     g_panelTextureHeight = 0;
static int     g_panelSequence = 0;
static int     g_panelTextureSequence = 0;
static int     g_panelPointerX = 0;
static int     g_panelPointerY = 0;
static int     g_panelPointerDown = 0;
static int     g_panelPointerButtons = 0;
static volatile LONG g_panelClickSequence = 0;
static volatile LONG g_panelWheelSequence = 0;
static volatile LONG g_panelTextSequence = 0;
static volatile LONG g_panelTextCode = 0;
static int     g_panelWheelDelta = 0;
static float   g_panelDrawScaleX = 1.0f;
static float   g_panelDrawScaleY = 1.0f;
static HANDLE  g_panelMap = NULL;
static const unsigned char* g_panelView = NULL;
static bool    g_panelWritable = false;
static DWORD   g_panelHostRequestTick = 0;
static DWORD   g_panelHostFirstRequestTick = 0;
static DWORD   g_panelHostRestartTick = 0;
static int     g_lastWidth = 0;
static int     g_lastHeight = 0;
static volatile LONG g_imguiHookState = 0;
static ImVec2 g_buttonMin(0, 0);
static ImVec2 g_buttonMax(0, 0);
static ImVec2 g_panelMin(0, 0);
static ImVec2 g_panelMax(0, 0);
static int g_imguiFrameLogs = 0;
static int g_imguiRenderLogs = 0;

template <typename T>
static T ImGuiGlProc(const char* name)
{
    PROC proc = wglGetProcAddress(name);
    if (!proc)
    {
        HMODULE gl = GetModuleHandleA("opengl32.dll");
        if (gl) proc = GetProcAddress(gl, name);
    }
    return (T)proc;
}

#ifndef GL_ACTIVE_TEXTURE
#define GL_TEXTURE0 0x84C0
#define GL_ACTIVE_TEXTURE 0x84E0
#define GL_CLIENT_ACTIVE_TEXTURE 0x84E1
#define GL_ARRAY_BUFFER_BINDING 0x8894
#define GL_ELEMENT_ARRAY_BUFFER_BINDING 0x8893
#define GL_CURRENT_PROGRAM 0x8B8D
#define GL_VERTEX_ARRAY_BINDING 0x85B5
#define GL_ARRAY_BUFFER 0x8892
#define GL_ELEMENT_ARRAY_BUFFER 0x8893
#define GL_PIXEL_UNPACK_BUFFER 0x88EC
#define GL_PIXEL_UNPACK_BUFFER_BINDING 0x88EF
#define GL_UNPACK_ROW_LENGTH 0x0CF2
#define GL_UNPACK_SKIP_ROWS 0x0CF3
#define GL_UNPACK_SKIP_PIXELS 0x0CF4
#define GL_UNPACK_SWAP_BYTES 0x0CF0
#endif

static void ImGuiLog(const char* text)
{
    char base[MAX_PATH] = { 0 };
    char localDir[MAX_PATH] = { 0 };
    char localPath[MAX_PATH] = { 0 };
    if (GetEnvironmentVariableA("LOCALAPPDATA", base, MAX_PATH) > 0)
    {
        _snprintf_s(localDir, sizeof(localDir), _TRUNCATE,
                    "%s\\War3DeathSettlement", base);
        CreateDirectoryA(localDir, NULL);
        _snprintf_s(localPath, sizeof(localPath), _TRUNCATE,
                    "%s\\ddh-imgui.txt", localDir);
    }
    const char* paths[] =
    {
        "C:\\launch\\ddh-imgui.txt",
        "C:\\Users\\Public\\Documents\\War3DeathSettlement\\ddh-imgui.txt",
        localPath[0] ? localPath : NULL,
    };
    for (int i = 0; i < (int)(sizeof(paths) / sizeof(paths[0])); ++i)
    {
        if (!paths[i] || !paths[i][0]) continue;
        HANDLE file = CreateFileA(paths[i], FILE_APPEND_DATA,
                                  FILE_SHARE_READ | FILE_SHARE_WRITE, NULL,
                                  OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
        if (file == INVALID_HANDLE_VALUE) continue;
        DWORD written = 0;
        WriteFile(file, text, (DWORD)strlen(text), &written, NULL);
        WriteFile(file, "\r\n", 2, &written, NULL);
        CloseHandle(file);
        return;
    }
}

static int ReadMappedInt(const unsigned char* address)
{
    return *(const volatile LONG*)address;
}

static void RequestPanelHost(void)
{
    const DWORD now = GetTickCount();
    if (g_panelHostRequestTick && (DWORD)(now - g_panelHostRequestTick) < 3000) return;
    if (!g_panelHostFirstRequestTick) g_panelHostFirstRequestTick = now ? now : 1;
    g_panelHostRequestTick = now;
    DdhOverlaySetHtml(DDH_PANEL_HTML_PATH);
    if ((DWORD)(now - g_panelHostFirstRequestTick) >= 8000 &&
        (!g_panelHostRestartTick || (DWORD)(now - g_panelHostRestartTick) >= 15000))
    {
        g_panelHostRestartTick = now;
        ImGuiLog("Vue panel mapping timeout; force restarting ddh_web");
        DdhOverlayRestartHtml(DDH_PANEL_HTML_PATH);
    }
}

static bool EnsurePanelMapping(void)
{
    if (g_panelView) return true;
    DdhOverlayEnsureHtmlMapping();
    char name[96] = { 0 };
    _snprintf_s(name, sizeof(name), _TRUNCATE, "Local\\DdhHtml_%lu",
                (unsigned long)GetCurrentProcessId());
    HANDLE map = OpenFileMappingA(FILE_MAP_READ | FILE_MAP_WRITE, FALSE, name);
    DWORD writeError = map ? ERROR_SUCCESS : GetLastError();
    DWORD access = FILE_MAP_READ | FILE_MAP_WRITE;
    if (!map)
    {
        map = OpenFileMappingA(FILE_MAP_READ, FALSE, name);
        if (map) access = FILE_MAP_READ;
    }
    if (!map)
    {
        char line[192];
        _snprintf_s(line, sizeof(line), _TRUNCATE,
                    "Vue panel mapping open failed rw_err=%lu ro_err=%lu",
                    (unsigned long)writeError, (unsigned long)GetLastError());
        ImGuiLog(line);
        return false;
    }
    void* view = MapViewOfFile(map, access, 0, 0, 0);
    if (!view)
    {
        char line[160];
        _snprintf_s(line, sizeof(line), _TRUNCATE,
                    "Vue panel mapping view failed access=0x%lX err=%lu",
                    (unsigned long)access, (unsigned long)GetLastError());
        ImGuiLog(line);
        CloseHandle(map);
        return false;
    }
    g_panelMap = map;
    g_panelView = (const unsigned char*)view;
    g_panelWritable = (access & FILE_MAP_WRITE) != 0;
    g_panelHostFirstRequestTick = 0;
    g_panelHostRestartTick = 0;
    ImGuiLog(g_panelWritable
        ? "Vue panel shared mapping opened (read/write)"
        : "Vue panel shared mapping opened (read-only)");
    return true;
}

static bool RefreshPanelFrame(void)
{
    if (!EnsurePanelMapping())
    {
        RequestPanelHost();
        EnsurePanelMapping();
        return false;
    }

    const int magic = ReadMappedInt(g_panelView + 0);
    const int width = ReadMappedInt(g_panelView + 4);
    const int height = ReadMappedInt(g_panelView + 8);
    const int seq = ReadMappedInt(g_panelView + 12);
    if (magic != DDH_PANEL_MAGIC || width <= 0 || height <= 0 ||
        width > DDH_PANEL_MAX_W || height > DDH_PANEL_MAX_H || seq <= 0)
    {
        RequestPanelHost();
        return false;
    }
    if (seq == g_panelSequence) return true;

    const size_t bytes = (size_t)width * (size_t)height * 4u;
    if (!g_panelPixels)
        g_panelPixels = (unsigned char*)malloc((size_t)DDH_PANEL_MAX_W * DDH_PANEL_MAX_H * 4u);
    if (!g_panelPixels) return false;

    const unsigned char* source = g_panelView + DDH_PANEL_HEADER;
    memcpy(g_panelPixels, source, bytes);
    if (seq != ReadMappedInt(g_panelView + 12)) return false;

    g_panelSequence = seq;
    g_panelWidth = width;
    g_panelHeight = height;
    return true;
}

static void PublishPanelInput(void)
{
    if (!g_panelView || !g_panelWritable ||
        g_panelWidth <= 0 || g_panelHeight <= 0) return;
    unsigned char* input = const_cast<unsigned char*>(g_panelView) +
        DDH_PANEL_HEADER + (size_t)g_panelWidth * (size_t)g_panelHeight * 4u;
    *(int*)(input + 4) = g_panelPointerX;
    *(int*)(input + 8) = g_panelPointerY;
    *(int*)(input + 12) = (int)InterlockedCompareExchange(&g_panelClickSequence, 0, 0);
    *(int*)(input + 16) = (int)InterlockedCompareExchange(&g_panelWheelSequence, 0, 0);
    *(int*)(input + 20) = g_panelWheelDelta;
    *(int*)(input + 24) = g_panelPointerButtons;
    *(int*)(input + 28) = (int)InterlockedCompareExchange(&g_panelTextSequence, 0, 0);
    *(int*)(input + 32) = g_panelTextCode;
    /* Normalized x/y let WebHost map to the real CSS viewport instead of
       assuming the rendered capture is always exactly 900x600 CSS pixels. */
    *(int*)(input + 40) = (int)(((long long)g_panelPointerX * 10000) /
        (long long)g_panelWidth);
    *(int*)(input + 44) = (int)(((long long)g_panelPointerY * 10000) /
        (long long)g_panelHeight);
    MemoryBarrier();
    InterlockedIncrement((volatile LONG*)(input + 0));
}

static bool EnsurePanelTexture(void)
{
    RefreshPanelFrame();
    if (!g_panelPixels || g_panelWidth <= 0 || g_panelHeight <= 0) return false;
    if (g_panelTexture && g_panelTextureSequence == g_panelSequence) return true;

    GLint previousTexture = 0;
    GLint previousAlignment = 4;
    GLint previousRowLength = 0;
    GLint previousSkipRows = 0;
    GLint previousSkipPixels = 0;
    GLint previousSwapBytes = 0;
    GLint previousPixelUnpackBuffer = 0;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &previousTexture);
    glGetIntegerv(GL_UNPACK_ALIGNMENT, &previousAlignment);
    glGetIntegerv(GL_UNPACK_ROW_LENGTH, &previousRowLength);
    glGetIntegerv(GL_UNPACK_SKIP_ROWS, &previousSkipRows);
    glGetIntegerv(GL_UNPACK_SKIP_PIXELS, &previousSkipPixels);
    glGetIntegerv(GL_UNPACK_SWAP_BYTES, &previousSwapBytes);
    glGetIntegerv(GL_PIXEL_UNPACK_BUFFER_BINDING, &previousPixelUnpackBuffer);
    fn_bind_buffer_t bindBuffer = ImGuiGlProc<fn_bind_buffer_t>("glBindBuffer");
    if (bindBuffer) bindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);
    if (!g_panelTexture) glGenTextures(1, &g_panelTexture);
    glBindTexture(GL_TEXTURE_2D, g_panelTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    glPixelStorei(GL_UNPACK_SKIP_ROWS, 0);
    glPixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
    glPixelStorei(GL_UNPACK_SWAP_BYTES, 0);
    if (g_panelTextureWidth != g_panelWidth || g_panelTextureHeight != g_panelHeight)
    {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, g_panelWidth, g_panelHeight, 0,
                     GL_BGRA, GL_UNSIGNED_BYTE, g_panelPixels);
        g_panelTextureWidth = g_panelWidth;
        g_panelTextureHeight = g_panelHeight;
    }
    else
    {
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, g_panelWidth, g_panelHeight,
                        GL_BGRA, GL_UNSIGNED_BYTE, g_panelPixels);
    }
    g_panelTextureSequence = g_panelSequence;
    if (g_panelUploadLogs < 8)
    {
        char line[160];
        _snprintf_s(line, sizeof(line), _TRUNCATE,
                    "panel upload seq=%d size=%dx%d id=%u err=%04X",
                    g_panelSequence, g_panelWidth, g_panelHeight,
                    (unsigned)g_panelTexture, (unsigned)glGetError());
        ImGuiLog(line);
        ++g_panelUploadLogs;
    }
    if (bindBuffer) bindBuffer(GL_PIXEL_UNPACK_BUFFER, (GLuint)previousPixelUnpackBuffer);
    glPixelStorei(GL_UNPACK_SWAP_BYTES, previousSwapBytes);
    glPixelStorei(GL_UNPACK_SKIP_PIXELS, previousSkipPixels);
    glPixelStorei(GL_UNPACK_SKIP_ROWS, previousSkipRows);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, previousRowLength);
    glPixelStorei(GL_UNPACK_ALIGNMENT, previousAlignment);
    glBindTexture(GL_TEXTURE_2D, (GLuint)previousTexture);
    return true;
}

static void DrawOverlay(void)
{
    if (!g_imguiReady || !ImGui::GetCurrentContext()) return;

    RECT rc = { 0, 0, 0, 0 };
    if (!GetClientRect(g_imguiGameWindow, &rc)) return;
    const int width = rc.right - rc.left;
    const int height = rc.bottom - rc.top;
    if (width < 64 || height < 64) return;

    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize = ImVec2((float)width, (float)height);
    if (g_lastWidth != width || g_lastHeight != height)
    {
        g_lastWidth = width;
        g_lastHeight = height;
    }

    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplWin32_NewFrame();
    ImGui::NewFrame();

    const bool buttonAvailable = DdhWebUiAvailable() != 0;
    if (buttonAvailable)
    {
        /* Keep the settlement button left of KK's three top-right buttons. */
        g_buttonMin = ImVec2((float)width - 142.0f, 4.0f);
        g_buttonMax = ImVec2(g_buttonMin.x + 30.0f, g_buttonMin.y + 30.0f);
    }
    else
    {
        g_buttonMin = ImVec2(0, 0);
        g_buttonMax = ImVec2(0, 0);
    }
    const bool buttonHovered = buttonAvailable &&
        io.MousePos.x >= g_buttonMin.x && io.MousePos.x < g_buttonMax.x &&
        io.MousePos.y >= g_buttonMin.y && io.MousePos.y < g_buttonMax.y;
    if (buttonHovered && ImGui::IsMouseClicked(ImGuiMouseButton_Left))
        g_imguiOpen = !g_imguiOpen;

    ImDrawList* foreground = ImGui::GetForegroundDrawList();

    g_panelMin = ImVec2(0, 0);
    g_panelMax = ImVec2(0, 0);
    if (g_imguiOpen)
    {
        const float panelW = (float)(g_panelWidth > 0 ? g_panelWidth : 1200);
        const float panelH = (float)(g_panelHeight > 0 ? g_panelHeight : 760);
        const float fit = min(1.0f, min(((float)width - 16.0f) / panelW,
                                        ((float)height - 16.0f) / panelH));
        const float drawW = panelW * fit;
        const float drawH = panelH * fit;
        g_panelDrawScaleX = drawW > 0 ? panelW / drawW : 1.0f;
        g_panelDrawScaleY = drawH > 0 ? panelH / drawH : 1.0f;
        g_panelMin = ImVec2((float)width - drawW - 8.0f, 8.0f);
        if (g_panelMin.x < 8.0f) g_panelMin.x = 8.0f;
        g_panelMax = ImVec2(g_panelMin.x + drawW, g_panelMin.y + drawH);
        foreground->AddRectFilled(
            ImVec2(g_panelMin.x - 4.0f, g_panelMin.y - 4.0f),
            ImVec2(g_panelMax.x + 4.0f, g_panelMax.y + 4.0f),
            IM_COL32(14, 14, 12, 252), 4.0f);
        foreground->AddRect(
            ImVec2(g_panelMin.x - 4.0f, g_panelMin.y - 4.0f),
            ImVec2(g_panelMax.x + 4.0f, g_panelMax.y + 4.0f),
            IM_COL32(190, 146, 54, 255), 4.0f);

        if (EnsurePanelTexture())
        {
            foreground->AddImage((ImTextureID)(intptr_t)g_panelTexture,
                                 g_panelMin, g_panelMax);
        }
        else
        {
            foreground->AddText(
                ImGui::GetFont(), 16.0f,
                ImVec2(g_panelMin.x + 18.0f, g_panelMin.y + 20.0f),
                IM_COL32(255, 212, 105, 255),
                "\xE6\xAD\xA3\xE5\x9C\xA8\xE5\x90\xAF\xE5\x8A\xA8 Vue \xE7\xBB\x93\xE7\xAE\x97\xE9\xA1\xB5...");
        }
        PublishPanelInput();
    }

    /* Draw after the panel so its header can never cover the button. */
    if (buttonAvailable)
    {
        foreground->AddRectFilled(g_buttonMin, g_buttonMax,
                                  buttonHovered ? IM_COL32(76, 62, 30, 245)
                                                : IM_COL32(32, 28, 18, 238), 4.0f);
        foreground->AddRect(g_buttonMin, g_buttonMax, IM_COL32(205, 162, 72, 255), 4.0f);
        foreground->AddText(ImGui::GetFont(), 16.0f,
                            ImVec2(g_buttonMin.x + 7.0f, g_buttonMin.y + 5.0f),
                            IM_COL32(255, 210, 100, 255), DdhOverlayMarkerText());
    }

    ImGui::Render();
    ImDrawData* drawData = ImGui::GetDrawData();
    if (g_imguiFrameLogs < 6 && drawData)
    {
        char line[160];
        _snprintf_s(line, sizeof(line), _TRUNCATE,
                    "frame=%d size=%.0fx%.0f lists=%d vtx=%d idx=%d err=%04X",
                    g_imguiFrameLogs + 1, io.DisplaySize.x, io.DisplaySize.y,
                    drawData->CmdListsCount, drawData->TotalVtxCount,
                    drawData->TotalIdxCount, (unsigned)glGetError());
        ImGuiLog(line);
        ++g_imguiFrameLogs;
    }

    /* imgui_impl_opengl2 does not restore client-array enables, active texture,
       VBO/VAO or program bindings. War3 1.27 uses all of them and would present
       a fully black frame after ImGui. Preserve the complete game state here. */
    GLint activeTexture = GL_TEXTURE0;
    GLint clientActiveTexture = GL_TEXTURE0;
    GLint arrayBuffer = 0;
    GLint elementBuffer = 0;
    GLint currentProgram = 0;
    GLint currentVao = 0;
    glGetIntegerv(GL_ACTIVE_TEXTURE, &activeTexture);
    glGetIntegerv(GL_CLIENT_ACTIVE_TEXTURE, &clientActiveTexture);
    glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &arrayBuffer);
    glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &elementBuffer);
    glGetIntegerv(GL_CURRENT_PROGRAM, &currentProgram);
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING, &currentVao);

    glPushAttrib(GL_ALL_ATTRIB_BITS);
    glPushClientAttrib(GL_CLIENT_ALL_ATTRIB_BITS);

    fn_bind_buffer_t bindBuffer = ImGuiGlProc<fn_bind_buffer_t>("glBindBuffer");
    fn_use_program_t useProgram = ImGuiGlProc<fn_use_program_t>("glUseProgram");
    fn_bind_vao_t bindVao = ImGuiGlProc<fn_bind_vao_t>("glBindVertexArray");
    fn_active_texture_t activeTexFn = ImGuiGlProc<fn_active_texture_t>("glActiveTexture");
    fn_active_texture_t clientTexFn = ImGuiGlProc<fn_active_texture_t>("glClientActiveTexture");
    if (bindBuffer)
    {
        bindBuffer(GL_ARRAY_BUFFER, 0);
        bindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }
    if (useProgram && currentProgram) useProgram(0);
    if (bindVao && currentVao) bindVao(0);

    ImGui_ImplOpenGL3_RenderDrawData(drawData);
    if (g_imguiRenderLogs < 6)
    {
        char line[192];
        int texCount = drawData && drawData->Textures ? drawData->Textures->Size : 0;
        ImTextureData* tex = texCount > 0 ? (*drawData->Textures)[0] : NULL;
        _snprintf_s(line, sizeof(line), _TRUNCATE,
                    "render=%d err=%04X texCount=%d status=%d id=%llu wh=%dx%d",
                    g_imguiRenderLogs + 1, (unsigned)glGetError(), texCount,
                    tex ? (int)tex->Status : -1,
                    tex ? (unsigned long long)tex->TexID : 0ull,
                    tex ? tex->Width : 0, tex ? tex->Height : 0);
        ImGuiLog(line);
        ++g_imguiRenderLogs;
    }

    if (bindVao) bindVao((GLuint)currentVao);
    if (useProgram) useProgram((GLuint)currentProgram);
    if (bindBuffer)
    {
        bindBuffer(GL_ARRAY_BUFFER, (GLuint)arrayBuffer);
        bindBuffer(GL_ELEMENT_ARRAY_BUFFER, (GLuint)elementBuffer);
    }
    if (activeTexFn) activeTexFn((GLenum)activeTexture);
    if (clientTexFn) clientTexFn((GLenum)clientActiveTexture);
    glPopClientAttrib();
    glPopAttrib();
}

static bool InitImGui(void)
{
    if (g_imguiReady) return true;
    if (!g_imguiGameWindow || !GetModuleHandleA("opengl32.dll")) return false;

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    io.IniFilename = NULL;
    io.LogFilename = NULL;

    ImFontConfig cfg;
    cfg.OversampleH = 1;
    cfg.OversampleV = 1;
    if (!io.Fonts->AddFontFromFileTTF("C:\\Windows\\Fonts\\msyh.ttc", 16.0f, &cfg,
                                      io.Fonts->GetGlyphRangesChineseFull()))
        io.Fonts->AddFontDefault();

    ImGui::StyleColorsDark();
    if (!ImGui_ImplWin32_Init(g_imguiGameWindow)) return false;
    if (!ImGui_ImplOpenGL3_Init("#version 130")) return false;
    g_imguiReady = true;
    ImGuiLog("ImGui 1.92.2 ready");
    return true;
}

static BOOL __fastcall CursorLayerUpdateDetour(void* self, int edx,
                                               int a1, int a2, int a3)
{
    BOOL result = g_realCursorLayerUpdate
        ? g_realCursorLayerUpdate(self, edx, a1, a2, a3)
        : FALSE;
    if (!g_imguiReady) InitImGui();
    __try { DrawOverlay(); }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        ImGuiLog("DrawOverlay exception");
    }
    return result;
}

static void InstallCursorHook(void)
{
    if (InterlockedCompareExchange(&g_imguiHookState, 1, 0) != 0) return;
    HMODULE game = GetModuleHandleA("game.dll");
    if (!game)
    {
        InterlockedExchange(&g_imguiHookState, 0);
        return;
    }

    void* target = (uint8_t*)game + 0xC97D0u;
    HANDLE threads[512] = { 0 };
    int threadCount = 0;
    LONG error = DetourTransactionBegin();
    if (error == NO_ERROR)
    {
        error = DetourUpdateThread(GetCurrentThread());
        HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
        if (snap != INVALID_HANDLE_VALUE)
        {
            const DWORD pid = GetCurrentProcessId();
            const DWORD self = GetCurrentThreadId();
            THREADENTRY32 te;
            memset(&te, 0, sizeof(te));
            te.dwSize = sizeof(te);
            if (Thread32First(snap, &te))
            {
                do
                {
                    if (te.th32OwnerProcessID != pid || te.th32ThreadID == self) continue;
                    if (threadCount >= (int)(sizeof(threads) / sizeof(threads[0]))) break;
                    HANDLE thread = OpenThread(
                        THREAD_SUSPEND_RESUME | THREAD_GET_CONTEXT | THREAD_SET_CONTEXT,
                        FALSE, te.th32ThreadID);
                    if (!thread) continue;
                    if (DetourUpdateThread(thread) != NO_ERROR)
                    {
                        CloseHandle(thread);
                        continue;
                    }
                    threads[threadCount++] = thread;
                } while (Thread32Next(snap, &te));
            }
            CloseHandle(snap);
        }
    }
    if (error == NO_ERROR)
        error = DetourAttach(&(PVOID&)target, (PVOID)CursorLayerUpdateDetour);
    if (error == NO_ERROR) error = DetourTransactionCommit();
    else DetourTransactionAbort();
    for (int i = 0; i < threadCount; ++i) CloseHandle(threads[i]);
    if (error == NO_ERROR)
    {
        g_realCursorLayerUpdate = (fn_cursor_layer_update_t)target;
        InterlockedExchange(&g_imguiHookState, 2);
        ImGuiLog("Detours cursor hook installed");
    }
    else
    {
        InterlockedExchange(&g_imguiHookState, 3);
        char line[128];
        _snprintf_s(line, sizeof(line), _TRUNCATE,
                    "Detours cursor hook failed: %ld", error);
        ImGuiLog(line);
    }
}

extern "C" void DdhImGuiInit(HWND gameWindow)
{
    if (!gameWindow || g_imguiGameWindow) return;
    g_imguiGameWindow = gameWindow;
    DdhOverlayEnsureHtmlMapping();
    ImGuiLog("Vue panel mapping prepared by game process");
    InstallCursorHook();
}

extern "C" int DdhImGuiWndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
{
    if (!g_imguiReady) return 0;
    if (g_imguiOpen && msg == WM_KEYDOWN && wp == VK_ESCAPE &&
        (lp & 0x40000000L) == 0)
    {
        g_imguiOpen = false;
        return 1;
    }
    if (g_imguiOpen && (msg == WM_CHAR || msg == WM_IME_CHAR) &&
        g_panelView && g_panelWidth > 0 && g_panelHeight > 0)
    {
        const unsigned char* input = g_panelView + DDH_PANEL_HEADER +
            (size_t)g_panelWidth * (size_t)g_panelHeight * 4u;
        if (ReadMappedInt(input + 36) != 0)
        {
            InterlockedExchange(&g_panelTextCode, (LONG)wp);
            InterlockedIncrement(&g_panelTextSequence);
            return 1;
        }
    }
    ImGui_ImplWin32_WndProcHandler(hwnd, msg, wp, lp);
    ImGuiIO& io = ImGui::GetIO();
    /* 只有结算页真正打开时才让 ImGui 接管输入。g_imguiReady 只表示渲染器已
       初始化，不能拿它判断用户正在操作覆盖层；否则覆盖层关闭时也会把引擎
       面板的鼠标点击全部跳过。 */
    if (g_imguiOpen && (io.WantCaptureMouse || io.WantCaptureKeyboard)) return 1;

    if (msg == WM_MOUSEMOVE || msg == WM_LBUTTONDOWN || msg == WM_LBUTTONUP ||
        msg == WM_LBUTTONDBLCLK || msg == WM_MOUSEWHEEL)
    {
        float x = (float)(short)LOWORD(lp);
        float y = (float)(short)HIWORD(lp);
        int wheelDelta = 0;
        if (msg == WM_MOUSEWHEEL)
        {
            POINT point = { (short)LOWORD(lp), (short)HIWORD(lp) };
            ScreenToClient(hwnd, &point);
            x = (float)point.x;
            y = (float)point.y;
            wheelDelta = (int)(short)HIWORD(wp);
        }
        const bool overButton =
            x >= g_buttonMin.x && x < g_buttonMax.x &&
            y >= g_buttonMin.y && y < g_buttonMax.y;
        const bool overPanel = g_imguiOpen &&
            x >= g_panelMin.x && x < g_panelMax.x &&
            y >= g_panelMin.y && y < g_panelMax.y;
        const bool panelTracking = overPanel || (g_imguiOpen && g_panelPointerDown);
        if (panelTracking)
        {
            g_panelPointerX = (int)((x - g_panelMin.x) * g_panelDrawScaleX);
            g_panelPointerY = (int)((y - g_panelMin.y) * g_panelDrawScaleY);
            if (msg == WM_MOUSEWHEEL)
            {
                g_panelWheelDelta = wheelDelta;
                InterlockedIncrement(&g_panelWheelSequence);
            }
            if (msg == WM_LBUTTONDOWN)
            {
                if (!g_panelPointerDown) SetCapture(hwnd);
                g_panelPointerDown = 1;
                g_panelPointerButtons = 1;
            }
            if (msg == WM_LBUTTONUP)
            {
                if (g_panelPointerDown) InterlockedIncrement(&g_panelClickSequence);
                g_panelPointerDown = 0;
                g_panelPointerButtons = 0;
                if (GetCapture() == hwnd) ReleaseCapture();
            }
        }
        else if (msg == WM_LBUTTONUP)
        {
            g_panelPointerDown = 0;
            g_panelPointerButtons = 0;
            if (GetCapture() == hwnd) ReleaseCapture();
        }
        if (overButton || panelTracking) return 1;
    }
    return 0;
}

extern "C" int DdhImGuiActive(void)
{
    return (g_imguiReady && g_imguiOpen) ? 1 : 0;
}
