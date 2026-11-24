//----------------------------------------------------------------------------
// fake_war3.cpp -- 只用于本项目自测的假 war3.exe（控制台程序）
//   加载同目录下的 game.dll（假的），调它的 fake_start()，然后挂着等工具来读。
//   进程名就是 war3，所以工具的“按进程名找游戏”这条路径也会被验证到。
//----------------------------------------------------------------------------

#include <windows.h>
#include <stdio.h>
#include <string.h>

#pragma comment(lib, "user32.lib")

typedef int  (*fn_start)(void);
typedef void (*fn_stop)(void);

/* v14 fake window: ddh posts WM_APP+0xDE here for unit-attribute requests.
   Without a visible window ddh can only process attributes on the next damage
   event, which makes the "no damage" long-run test unable to fill the columns. */
static LRESULT CALLBACK FakeWndProc(HWND h, UINT m, WPARAM w, LPARAM l)
{
    return DefWindowProcA(h, m, w, l);
}

static HWND CreateFakeGameWindow(void)
{
    WNDCLASSA wc;
    memset(&wc, 0, sizeof(wc));
    wc.lpfnWndProc = FakeWndProc;
    wc.hInstance = GetModuleHandleA(NULL);
    wc.lpszClassName = "Warcraft III";
    RegisterClassA(&wc);
    HWND h = CreateWindowExA(0, "Warcraft III", "Warcraft III (fake)", WS_OVERLAPPEDWINDOW,
                             -12000, -12000, 640, 480, NULL, NULL, wc.hInstance, NULL);
    if (h) ShowWindow(h, SW_SHOWNOACTIVATE);
    return h;
}

static void PumpForSecond(void)
{
    DWORD end = GetTickCount() + 1000;
    while (GetTickCount() < end)
    {
        MSG msg;
        while (PeekMessageA(&msg, NULL, 0, 0, PM_REMOVE))
        {
            TranslateMessage(&msg);
            DispatchMessageA(&msg);
        }
        Sleep(10);
    }
}

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
    HWND wnd = (rc == 0) ? CreateFakeGameWindow() : NULL;
    printf("[fake war3] running, pid=%lu, rc=%d, hwnd=%p, will exit after %d s\n",
           GetCurrentProcessId(), rc, (void*)wnd, seconds);
    fflush(stdout);

    for (int i = 0; i < seconds; i++)
    {
        PumpForSecond();
        if (i % 10 == 9) { printf("[fake war3] t+%ds alive\n", i + 1); fflush(stdout); }
    }

    if (wnd) DestroyWindow(wnd);
    if (stop) stop();
    printf("[fake war3] exiting\n");
    return 0;
}
