//==============================================================================
// UDamageWatcherSmoke.cpp —— UDamageWatcher.dll 的本机自检程序（游戏外运行）
//
// 目的：在没有 JAPI / ydbase 的普通进程里加载插件 DLL，
//       验证它能"安全降级"：写出日志、生成 ini、不崩溃。
//
// 用法： UDamageWatcherSmoke.exe <UDamageWatcher.dll> [假插件目录]
//
// 退出码：0 = 通过；非 0 = 失败
//==============================================================================

#define _CRT_SECURE_NO_WARNINGS 1

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>

static void MakeDirTree(const char* dir)
{
    char tmp[MAX_PATH];
    strncpy_s(tmp, MAX_PATH, dir, _TRUNCATE);
    for (char* p = tmp; *p; ++p) {
        if (*p == '\\' || *p == '/') {
            char c = *p; *p = 0;
            if (strlen(tmp) > 2) CreateDirectoryA(tmp, NULL);
            *p = c;
        }
    }
    CreateDirectoryA(tmp, NULL);
}

int main(int argc, char** argv)
{
    if (argc < 2) {
        printf("usage: UDamageWatcherSmoke.exe <UDamageWatcher.dll> [fake-plugin-dir]\n");
        return 2;
    }

    char src[MAX_PATH];
    GetFullPathNameA(argv[1], MAX_PATH, src, NULL);
    if (GetFileAttributesA(src) == INVALID_FILE_ATTRIBUTES) {
        printf("FAIL: 找不到 DLL: %s\n", src);
        return 3;
    }

    char fakeDir[MAX_PATH];
    if (argc >= 3) {
        GetFullPathNameA(argv[2], MAX_PATH, fakeDir, NULL);
    } else {
        strncpy_s(fakeDir, MAX_PATH, src, _TRUNCATE);
        char* slash = strrchr(fakeDir, '\\');
        if (slash) *slash = 0;
        strncat_s(fakeDir, MAX_PATH, "\\_selftest\\watcher", _TRUNCATE);
    }
    MakeDirTree(fakeDir);

    char dst[MAX_PATH];
    _snprintf_s(dst, MAX_PATH, _TRUNCATE, "%s\\UDamageWatcher.dll", fakeDir);
    printf("src dll  : %s\n", src);
    printf("dst dll  : %s\n", dst);
    printf("fake dir : %s\n", fakeDir);

    // 复制 DLL。
    // 陷阱：如果用户传的 <DLL> 本身就在 <假目录> 里（src == dst），
    //       任何"先删目标再复制"的做法都会把源文件删掉，导致复制失败。
    //       所以 src == dst 时直接跳过复制。
    if (_stricmp(src, dst) != 0) {
        BOOL okCopy = CopyFileA(src, dst, FALSE);   // 允许覆盖
        if (!okCopy) {
            DWORD e1 = GetLastError();
            if (e1 == ERROR_SHARING_VIOLATION || e1 == ERROR_ACCESS_DENIED) {
                // 目标被占用（上一次自检残留的进程/线程仍持有映像），删掉重试
                DeleteFileA(dst);
                okCopy = CopyFileA(src, dst, FALSE);
            }
            if (!okCopy) {
                DWORD e2 = GetLastError();
                printf("FAIL: 复制 DLL 失败 err=%lu (首次 err=%lu)\n", e2, e1);
                return 4;
            }
        }
    } else {
        printf("(src 与 dst 相同，跳过复制，直接用现有文件)\n");
    }

    char logPath[MAX_PATH], iniPath[MAX_PATH];
    _snprintf_s(logPath, MAX_PATH, _TRUNCATE, "%s\\UDamageWatcher.log", fakeDir);
    _snprintf_s(iniPath, MAX_PATH, _TRUNCATE, "%s\\UDamageWatcher.ini", fakeDir);
    DeleteFileA(logPath);
    DeleteFileA(iniPath);   // 一起验证"缺失时生成默认 ini"

    printf("log      : %s\n", logPath);
    printf("ini      : %s\n", iniPath);

    SetEnvironmentVariableA("UDW_WAIT_MS", "1500");   // 缩短等待，别自检等 60 秒

    printf("preload  : yd_jass_api=%p ydbase=%p  (都应为 00000000)\n",
           (void*)GetModuleHandleA("yd_jass_api.dll"),
           (void*)GetModuleHandleA("ydbase.dll"));

    HMODULE h = LoadLibraryA(dst);
    if (!h) { printf("FAIL: LoadLibrary err=%lu\n", GetLastError()); return 5; }
    printf("OK       : LoadLibrary\n");

    typedef const char* (__cdecl *fn_name)(void);
    typedef void        (__cdecl *fn_init)(void);

    fn_name getName = (fn_name)(void*)GetProcAddress(h, "PluginName");
    fn_init init    = (fn_init)(void*)GetProcAddress(h, "Initialize");
    printf("exports  : PluginName=%p Initialize=%p\n", (void*)getName, (void*)init);
    if (!getName || !init) { printf("FAIL: 缺少导出\n"); FreeLibrary(h); return 6; }
    printf("name     : %s\n", getName());
    if (strcmp(getName(), "UDamageWatcher") != 0) {
        printf("FAIL: PluginName 不是 UDamageWatcher\n"); FreeLibrary(h); return 6;
    }

    init();
    printf("OK       : Initialize() 第 1 次\n");
    Sleep(300);
    init();
    printf("OK       : Initialize() 第 2 次（幂等）\n");

    Sleep(4000);
    printf("OK       : 进程仍然存活（未崩溃）\n");

    if (GetFileAttributesA(logPath) == INVALID_FILE_ATTRIBUTES) {
        printf("FAIL: 没有生成日志 %s\n", logPath); FreeLibrary(h); return 7;
    }
    if (GetFileAttributesA(iniPath) == INVALID_FILE_ATTRIBUTES) {
        printf("FAIL: 没有生成默认 ini %s\n", iniPath); FreeLibrary(h); return 8;
    }

    FILE* f = fopen(logPath, "rb");
    if (!f) { printf("FAIL: 打不开日志\n"); FreeLibrary(h); return 9; }
    char buf[8192] = { 0 };
    size_t got = fread(buf, 1, sizeof(buf) - 1, f);
    buf[got] = 0;
    fclose(f);
    printf("\n---- UDamageWatcher.log (%u 字节) ----\n%s\n---- end ----\n", (unsigned)got, buf);

    int ok = 1;
    if (!strstr(buf, "UDamageWatcherHook")) { printf("FAIL: 日志缺版本行\n"); ok = 0; }
    if (!strstr(buf, "enable="))            { printf("FAIL: 日志缺配置行\n"); ok = 0; }
    // backend 默认是 auto：本机自检宿主里没有 ydbase ⇒ 日志里应出现
    //   "backend=auto 且进程里没有 ydbase.dll：改用 native 模式（引擎直连 Game.dll）"
    // 接着因为没有 game.dll，走"未找到 Game.dll + 安全退出"分支。
    if (!strstr(buf, "backend=auto"))       { printf("FAIL: log missing backend=auto line\n"); ok = 0; }
    if (!strstr(buf, "ydbase"))             { printf("FAIL: log missing ydbase mention\n"); ok = 0; }
    // v1.3.3 的调试日志开关必须被解析并出现在配置行里（只用 ASCII 断言）
    if (!strstr(buf, "debug="))             { printf("FAIL: log missing debug= config key\n"); ok = 0; }
    // 旧的 TextTag 飘字那套已经整体删掉：这些键/自检都不该再出现
    if (strstr(buf, "tt_lifespan="))        { printf("FAIL: stale TextTag config key present\n"); ok = 0; }
    if (strstr(buf, "wraptest"))            { printf("FAIL: stale TextTag wrap self-test present\n"); ok = 0; }

    // 中文断言用十六进制转义写死，避免"源文件编码 vs 编译器 /utf-8 vs 日志编码"
    // 三者不一致导致误判。日志按 ANSI(GBK) 写，这里也按 GBK 字节比对：
    //   "未找到"     = CE B4 D5 D2 B5 BD
    //   "安全退出"   = B0 B2 C8 AB CD CB B3 F6
    if (!strstr(buf, "\xCE\xB4\xD5\xD2\xB5\xBD"))         { printf("FAIL: 日志缺'未找到'\n"); ok = 0; }
    if (!strstr(buf, "\xB0\xB2\xC8\xAB\xCD\xCB\xB3\xF6")) { printf("FAIL: 日志缺'安全退出'\n"); ok = 0; }

    FreeLibrary(h);
    printf(ok ? "\nRESULT: PASS\n" : "\nRESULT: FAIL\n");
    return ok ? 0 : 10;
}
