//----------------------------------------------------------------------------
// fake_war3.cpp -- 只用于本项目自测的假 war3.exe（控制台程序）
//   加载同目录下的 game.dll（假的），调它的 fake_start()，然后挂着等工具来读。
//   进程名就是 war3，所以工具的“按进程名找游戏”这条路径也会被验证到。
//----------------------------------------------------------------------------

#include <windows.h>
#include <stdio.h>

typedef int  (*fn_start)(void);
typedef void (*fn_stop)(void);

int main(int argc, char** argv)
{
    int seconds = 90;
    if (argc > 1) seconds = atoi(argv[1]);
    if (seconds <= 0) seconds = 90;

    HMODULE h = LoadLibraryA("game.dll");
    if (!h)
    {
        printf("[fake war3] LoadLibrary(game.dll) failed, err=%lu\n", GetLastError());
        return 1;
    }

    fn_start start = (fn_start)GetProcAddress(h, "fake_start");
    fn_stop  stop  = (fn_stop) GetProcAddress(h, "fake_stop");
    if (!start)
    {
        printf("[fake war3] game.dll has no fake_start\n");
        return 2;
    }

    int rc = start();
    printf("[fake war3] running, pid=%lu, rc=%d, will exit after %d s\n",
           GetCurrentProcessId(), rc, seconds);
    fflush(stdout);

    for (int i = 0; i < seconds; i++)
    {
        Sleep(1000);
        if (i % 10 == 9) { printf("[fake war3] t+%ds alive\n", i + 1); fflush(stdout); }
    }

    if (stop) stop();
    printf("[fake war3] exiting\n");
    return 0;
}
