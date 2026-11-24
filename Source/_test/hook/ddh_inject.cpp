//----------------------------------------------------------------------------
// ddh_inject.cpp -- 32-bit injector: LoadLibrary("ddh.dll") into a running game.
//
// 为什么用 32 位注入器：从 64 位进程往 WOW64 目标注入时要自己找 32 位 kernel32
// 的 LoadLibraryA 地址，麻烦且容易错。32 位注入器里 LoadLibraryA 的地址和目标进程里
// 完全一样，用最经典的 CreateRemoteThread 就行。
//
// 用法：
//     ddh_inject.exe <pid> <dll 绝对路径> [--eject]
// 退出码：0 成功；1 参数/打开进程失败；2 注入失败
//----------------------------------------------------------------------------

#include <windows.h>
#include <tlhelp32.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char** argv)
{
    if (argc < 3)
    {
        printf("用法: ddh_inject.exe <pid> <ddh.dll 绝对路径> [--eject]\n");
        return 1;
    }

    DWORD pid = (DWORD)atoi(argv[1]);
    const char* dll = argv[2];
    bool eject = (argc > 3 && strcmp(argv[3], "--eject") == 0);

    if (GetFileAttributesA(dll) == INVALID_FILE_ATTRIBUTES)
    {
        printf("[inject] DLL 不存在: %s\n", dll);
        return 1;
    }

    HANDLE h = OpenProcess(PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION | PROCESS_VM_OPERATION |
                           PROCESS_VM_WRITE | PROCESS_VM_READ, FALSE, pid);
    if (!h)
    {
        printf("[inject] OpenProcess(%lu) 失败: %lu（游戏可能是管理员权限，注入器也要提权）\n", pid, GetLastError());
        return 1;
    }

    // 1) 在目标里分配并写入 DLL 路径
    SIZE_T len = strlen(dll) + 1;
    void* remote = VirtualAllocEx(h, NULL, len, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (!remote) { printf("[inject] VirtualAllocEx 失败: %lu\n", GetLastError()); CloseHandle(h); return 2; }
    if (!WriteProcessMemory(h, remote, dll, len, NULL))
    {
        printf("[inject] WriteProcessMemory 失败: %lu\n", GetLastError());
        VirtualFreeEx(h, remote, 0, MEM_RELEASE); CloseHandle(h); return 2;
    }

    // 2) kernel32 里的 LoadLibraryA / FreeLibrary（32 位进程里地址一致）
    HMODULE k32 = GetModuleHandleA("kernel32.dll");
    FARPROC proc = eject ? GetProcAddress(k32, "FreeLibrary") : GetProcAddress(k32, "LoadLibraryA");
    if (!proc) { printf("[inject] 找不到导出函数\n"); return 2; }

    // 3) 远程线程执行（eject 时参数是模块句柄而不是路径字符串）
    DWORD tid = 0;
    HANDLE th = NULL;
    if (eject)
    {
        // 需要先把目标里的 ddh.dll 模块句柄找出来（用 Toolhelp 在目标里枚举）
        HMODULE target = NULL;
        HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, pid);
        if (snap != INVALID_HANDLE_VALUE)
        {
            MODULEENTRY32W me; memset(&me, 0, sizeof(me)); me.dwSize = sizeof(me);
            if (Module32FirstW(snap, &me))
            {
                do
                {
                    if (_wcsicmp(me.szModule, L"ddh.dll") == 0) { target = me.hModule; break; }
                } while (Module32NextW(snap, &me));
            }
            CloseHandle(snap);
        }
        if (!target) { printf("[inject] 目标进程里没有 ddh.dll\n"); CloseHandle(h); return 2; }
        th = CreateRemoteThread(h, NULL, 0, (LPTHREAD_START_ROUTINE)proc, target, 0, &tid);
    }
    else
    {
        th = CreateRemoteThread(h, NULL, 0, (LPTHREAD_START_ROUTINE)proc, remote, 0, &tid);
    }

    if (!th)
    {
        printf("[inject] CreateRemoteThread 失败: %lu\n", GetLastError());
        if (!eject) VirtualFreeEx(h, remote, 0, MEM_RELEASE);
        CloseHandle(h);
        return 2;
    }

    WaitForSingleObject(th, 8000);
    DWORD code = 0;
    GetExitCodeThread(th, &code);
    CloseHandle(th);
    if (!eject) VirtualFreeEx(h, remote, 0, MEM_RELEASE);
    CloseHandle(h);

    if (eject)
    {
        printf("[inject] FreeLibrary 返回 %lu\n", code);
        return 0;
    }
    if (code == 0)
    {
        printf("[inject] LoadLibrary 返回 0 —— DLL 加载失败（位数不对？路径不可读？）\n");
        return 2;
    }
    printf("[inject] 注入成功: ddh.dll @ 0x%08lX (pid=%lu)\n", code, pid);
    return 0;
}
