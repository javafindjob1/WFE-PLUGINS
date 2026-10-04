//==============================================================================
// UDWInject.cpp —— 32 位小注入器（干的事和 WFE 的 Auto-inject 完全一样）
//
// 为什么需要它：插件是个 DLL，必须有人把它 LoadLibrary 进 war3.exe。
// 启动器（YDWE）与 WFE 都能做这件事，但有时两边都没开 ⇒ 游戏里什么都没有。
// 这个小工具自己等魔兽起来、等 Game.dll 就绪，然后把插件注入进去，与任何启动器无关。
//
// 用法：
//   UDWInject.exe [--watch] [--dll <插件dll路径>]
//     --watch  ：常驻，每次新出现 war3.exe 都注入一次（推荐：双击一次就不用管了）
//     不加 --watch：只处理当前/下一次出现的 war3.exe，注完就退出
//   默认 dll 路径 = 本 exe 同目录下的 UDamageWatcher.dll
//
// 退出码：0 = 至少成功注入过一次；非 0 = 没成功
//==============================================================================

#define _CRT_SECURE_NO_WARNINGS 1
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <tlhelp32.h>
#include <stdio.h>
#include <string.h>

static char g_dll[MAX_PATH] = { 0 };
static char g_log[MAX_PATH] = { 0 };

static void LogIt(const char* fmt, ...)
{
    char body[1024];
    va_list ap;
    va_start(ap, fmt);
    _vsnprintf_s(body, sizeof(body), _TRUNCATE, fmt, ap);
    va_end(ap);

    SYSTEMTIME st;
    GetLocalTime(&st);
    char line[1200];
    _snprintf_s(line, sizeof(line), _TRUNCATE, "[%02d:%02d:%02d.%03d] %s\r\n",
                st.wHour, st.wMinute, st.wSecond, st.wMilliseconds, body);
    fputs(line, stdout);
    fflush(stdout);
    if (g_log[0]) {
        FILE* f = fopen(g_log, "ab");
        if (f) { fputs(line, f); fclose(f); }
    }
}

// 找 war3.exe 的 PID（大小写不敏感）
static DWORD FindWar3Pid(void)
{
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snap == INVALID_HANDLE_VALUE) return 0;
    PROCESSENTRY32 pe;
    pe.dwSize = sizeof(pe);
    DWORD pid = 0;
    if (Process32First(snap, &pe)) {
        do {
            if (!_stricmp(pe.szExeFile, "war3.exe")) { pid = pe.th32ProcessID; break; }
        } while (Process32Next(snap, &pe));
    }
    CloseHandle(snap);
    return pid;
}

// 目标进程里有没有这个模块（我们要等 Game.dll 就绪再注，免得插件找不到游戏）
static int HasModule(DWORD pid, const char* name)
{
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, pid);
    if (snap == INVALID_HANDLE_VALUE) return 0;
    MODULEENTRY32 me;
    me.dwSize = sizeof(me);
    int found = 0;
    if (Module32First(snap, &me)) {
        do {
            if (!_stricmp(me.szModule, name)) { found = 1; break; }
        } while (Module32Next(snap, &me));
    }
    CloseHandle(snap);
    return found;
}

// 注入：VirtualAllocEx + WriteProcessMemory + CreateRemoteThread(LoadLibraryA)
static int InjectDll(DWORD pid, const char* dll)
{
    HANDLE h = OpenProcess(PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION |
                           PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ,
                           FALSE, pid);
    if (!h) {
        LogIt("OpenProcess 失败 err=%lu（%s）", GetLastError(),
              (GetLastError() == 5) ? "权限不足：试试以管理员身份运行" : "无法打开进程");
        return 0;
    }

    const SIZE_T len = strlen(dll) + 1;
    void* remote = VirtualAllocEx(h, NULL, len, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (!remote) { LogIt("VirtualAllocEx 失败 err=%lu", GetLastError()); CloseHandle(h); return 0; }

    SIZE_T written = 0;
    if (!WriteProcessMemory(h, remote, dll, len, &written) || written != len) {
        LogIt("WriteProcessMemory 失败 err=%lu", GetLastError());
        VirtualFreeEx(h, remote, 0, MEM_RELEASE); CloseHandle(h); return 0;
    }

    HMODULE k32 = GetModuleHandleA("kernel32.dll");
    FARPROC loadLib = GetProcAddress(k32, "LoadLibraryA");
    if (!loadLib) { LogIt("找不到 LoadLibraryA"); VirtualFreeEx(h, remote, 0, MEM_RELEASE); CloseHandle(h); return 0; }

    HANDLE th = CreateRemoteThread(h, NULL, 0, (LPTHREAD_START_ROUTINE)loadLib, remote, 0, NULL);
    if (!th) {
        LogIt("CreateRemoteThread 失败 err=%lu", GetLastError());
        VirtualFreeEx(h, remote, 0, MEM_RELEASE); CloseHandle(h); return 0;
    }
    WaitForSingleObject(th, 15000);
    DWORD code = 0;
    GetExitCodeThread(th, &code);
    CloseHandle(th);
    VirtualFreeEx(h, remote, 0, MEM_RELEASE);
    CloseHandle(h);

    if (!code) {
        LogIt("注入失败：目标进程里 LoadLibrary(\"%s\") 返回 0", dll);
        return 0;
    }
    LogIt("注入成功：war3.exe(PID %lu) <- %s（模块句柄 %08lX）", pid, dll, code);
    return 1;
}

int main(int argc, char** argv)
{
    int watch = 0;
    for (int i = 1; i < argc; ++i) {
        if (!_stricmp(argv[i], "--watch")) watch = 1;
        else if (!_stricmp(argv[i], "--dll") && i + 1 < argc) {
            strncpy_s(g_dll, MAX_PATH, argv[++i], _TRUNCATE);
        } else {
            LogIt("用法: UDWInject.exe [--watch] [--dll <插件dll路径>]");
            return 2;
        }
    }
    if (!g_dll[0]) {
        GetModuleFileNameA(NULL, g_dll, MAX_PATH);
        char* slash = strrchr(g_dll, '\\');
        if (slash) *(slash + 1) = 0; else g_dll[0] = 0;
        strncat_s(g_dll, MAX_PATH, "UDamageWatcher.dll", _TRUNCATE);
    }
    if (GetFileAttributesA(g_dll) == INVALID_FILE_ATTRIBUTES) {
        LogIt("找不到插件 DLL：%s", g_dll);
        return 3;
    }
    strncpy_s(g_log, MAX_PATH, g_dll, _TRUNCATE);
    char* slash = strrchr(g_log, '\\');
    if (slash) *(slash + 1) = 0; else g_log[0] = 0;
    strncat_s(g_log, MAX_PATH, "UDWInject.log", _TRUNCATE);

    LogIt("UDWInject 启动（%s模式）；插件 = %s", watch ? "常驻" : "单次", g_dll);

    DWORD lastPid = 0;
    int   injectedAny = 0;
    for (;;) {
        const DWORD pid = FindWar3Pid();
        if (pid && pid != lastPid) {
            lastPid = pid;
            LogIt("发现 war3.exe PID=%lu，等 Game.dll 就绪…", pid);
            for (int i = 0; i < 120; ++i) {                 // 最多等 120 秒
                if (!HasModule(pid, "Game.dll")) { Sleep(1000); continue; }
                Sleep(2000);                                 // 再缓 2 秒，让地图/插件环境就绪
                if (InjectDll(pid, g_dll)) injectedAny = 1;
                break;
            }
            if (!watch) break;
        }
        if (!watch && !pid) {                                // 单次模式且没找到游戏：等 5 分钟后退出
            static int waited = 0;
            if (++waited > 300) { LogIt("等不到 war3.exe，退出"); break; }
        }
        Sleep(1000);
    }

    LogIt("UDWInject 结束（%s）", injectedAny ? "注入成功过" : "没有成功注入");
    return injectedAny ? 0 : 1;
}
