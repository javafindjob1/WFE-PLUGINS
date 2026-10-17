//----------------------------------------------------------------------------
// realattach_host.cpp -- self-test helper: loads the REAL game.dll into a real
// 32-bit process, so War3DeathSettlement's attach layer (process -> module ->
// version detection -> globals) can be verified against the actual binary
// without launching the game itself.
//
// No game session exists, so ctx/ThisGame are expected to read as 0 and the
// tool must report "已连接…但游戏还没进地图" (the graceful path) instead of
// crashing or rejecting the version.
//
// Build: see build_realattach.ps1
//----------------------------------------------------------------------------

#include <windows.h>
#include <stdio.h>

int main(int argc, char** argv)
{
    const char* dllPath = (argc > 1) ? argv[1] : "C:\\3rd\\war5\\game.dll";
    int seconds = (argc > 2) ? atoi(argv[2]) : 120;
    if (seconds <= 0) seconds = 120;

    printf("[host] LoadLibrary(%s) ...\n", dllPath);
    fflush(stdout);

    HMODULE h = LoadLibraryA(dllPath);
    if (!h)
    {
        printf("[host] LoadLibrary failed, GetLastError=%lu\n", GetLastError());
        fflush(stdout);
        return 1;
    }

    printf("[host] loaded OK at base=0x%08X (pid=%lu)\n",
           (unsigned)(uintptr_t)h, GetCurrentProcessId());
    printf("[host] sleeping %d s so the tool can attach\n", seconds);
    fflush(stdout);

    for (int i = 0; i < seconds; i++)
    {
        Sleep(1000);
        if (i % 20 == 19) { printf("[host] t+%ds alive\n", i + 1); fflush(stdout); }
    }
    return 0;
}
