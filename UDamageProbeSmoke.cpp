//==============================================================================
// UDamageProbeSmoke.cpp —— UDamageProbe.dll 的本机自检程序（游戏外运行）
//
// 目的：在没有 JAPI / ydbase 的普通进程里加载探针 DLL 并调用 Initialize()，
//       验证它能"安全降级"：写出日志、不崩溃、不卡死。
//
// 用法：
//   UDamageProbeSmoke.exe <UDamageProbe.dll 的路径> [放日志的假目录]
//
// 它会：
//   1) 把 DLL 复制到一个"假插件目录"（避免污染真实插件目录）
//   2) 设 UDMAGE_PROBE_WAIT_MS=1500 缩短等待，避免自检等 60 秒
//   3) LoadLibrary 该 DLL，取 PluginName / Initialize 导出
//   4) 调用 Initialize() 两次（验证幂等）
//   5) 等日志写完，检查 <假目录>\UDamageProbe.log 是否出现且包含"安全退出"
//   6) 打印日志全文
//
// 退出码：0 = 通过；非 0 = 失败（原因打印出来）
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
        printf("usage: UDamageProbeSmoke.exe <UDamageProbe.dll> [fake-plugin-dir]\n");
        return 2;
    }

    char src[MAX_PATH];
    GetFullPathNameA(argv[1], MAX_PATH, src, NULL);
    if (GetFileAttributesA(src) == INVALID_FILE_ATTRIBUTES) {
        printf("FAIL: 找不到 DLL: %s\n", src);
        return 3;
    }

    // 假目录：默认放在 DLL 同级的 _selftest\probe
    char fakeDir[MAX_PATH];
    if (argc >= 3) {
        GetFullPathNameA(argv[2], MAX_PATH, fakeDir, NULL);
    } else {
        strncpy_s(fakeDir, MAX_PATH, src, _TRUNCATE);
        char* slash = strrchr(fakeDir, '\\');
        if (slash) *slash = 0;
        strncat_s(fakeDir, MAX_PATH, "\\_selftest\\probe", _TRUNCATE);
    }
    MakeDirTree(fakeDir);

    // 把 DLL 复制进假目录，让"DLL 所在目录"= 假目录
    char dst[MAX_PATH];
    _snprintf_s(dst, MAX_PATH, _TRUNCATE, "%s\\UDamageProbe.dll", fakeDir);
    if (!CopyFileA(src, dst, FALSE)) {
        printf("FAIL: 复制 DLL 到假目录失败 err=%lu (%s -> %s)\n",
               GetLastError(), src, dst);
        return 4;
    }

    char logPath[MAX_PATH];
    _snprintf_s(logPath, MAX_PATH, _TRUNCATE, "%s\\UDamageProbe.log", fakeDir);
    DeleteFileA(logPath);   // 清掉旧日志，保证看到的是本次结果

    printf("self     : %s\n", argv[0]);
    printf("src dll  : %s\n", src);
    printf("fake dir : %s\n", fakeDir);
    printf("log      : %s\n", logPath);

    // 缩短初始化等待时间（探针内部会读这个环境变量）
    SetEnvironmentVariableA("UDMAGE_PROBE_WAIT_MS", "1500");

    // ---- 先确认进程里确实没有 JAPI / ydbase ----
    HMODULE hj = GetModuleHandleA("yd_jass_api.dll");
    HMODULE hb = GetModuleHandleA("ydbase.dll");
    printf("preload  : yd_jass_api=%p ydbase=%p  (都应为 00000000)\n",
           (void*)hj, (void*)hb);

    HMODULE h = LoadLibraryA(dst);
    if (!h) {
        printf("FAIL: LoadLibrary err=%lu\n", GetLastError());
        return 5;
    }
    printf("OK       : LoadLibrary\n");

    typedef const char* (__cdecl *fn_name)(void);
    typedef void        (__cdecl *fn_init)(void);

    fn_name getName = (fn_name)(void*)GetProcAddress(h, "PluginName");
    fn_init init    = (fn_init)(void*)GetProcAddress(h, "Initialize");
    printf("exports  : PluginName=%p Initialize=%p\n", (void*)getName, (void*)init);

    if (!getName || !init) {
        printf("FAIL: 缺少 Initialize / PluginName 导出\n");
        FreeLibrary(h);
        return 6;
    }
    printf("name     : %s\n", getName());
    if (strcmp(getName(), "UDamageProbe") != 0) {
        printf("FAIL: PluginName 不等于 UDamageProbe\n");
        FreeLibrary(h);
        return 6;
    }

    // ---- 调用 Initialize 两次（第 2 次应当被幂等忽略） ----
    init();
    printf("OK       : Initialize() 第 1 次\n");
    Sleep(300);
    init();
    printf("OK       : Initialize() 第 2 次（应被忽略）\n");

    // 等初始化线程跑完（1500ms 超时 + 余量）
    Sleep(4000);
    printf("OK       : 进程仍然存活（未崩溃）\n");

    // ---- 检查日志 ----
    if (GetFileAttributesA(logPath) == INVALID_FILE_ATTRIBUTES) {
        printf("FAIL: 没有生成日志 %s\n", logPath);
        FreeLibrary(h);
        return 7;
    }

    FILE* f = fopen(logPath, "rb");
    if (!f) { printf("FAIL: 无法打开日志\n"); FreeLibrary(h); return 8; }
    char buf[8192] = { 0 };
    size_t got = fread(buf, 1, sizeof(buf) - 1, f);
    buf[got] = 0;
    fclose(f);

    printf("\n---- UDamageProbe.log (%u 字节) ----\n%s\n---- end ----\n", (unsigned)got, buf);

    int ok = 1;
    if (!strstr(buf, "UDamageProbe"))        { printf("FAIL: 日志里没有版本行\n");        ok = 0; }
    if (!strstr(buf, "未找到"))              { printf("FAIL: 日志里没有'未找到'降级行\n"); ok = 0; }
    if (!strstr(buf, "安全退出"))            { printf("FAIL: 日志里没有'安全退出'\n");     ok = 0; }

    FreeLibrary(h);
    printf(ok ? "\nRESULT: PASS\n" : "\nRESULT: FAIL\n");
    return ok ? 0 : 9;
}
