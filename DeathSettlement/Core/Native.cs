using System.Runtime.InteropServices;
using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>
/// Win32 互操作声明（只读内存访问用；本软件【绝不】写游戏内存，也【不】注入任何 DLL）。
/// </summary>
internal static class Native
{
    // ---- 进程访问权限 ----------------------------------------------------
    public const uint PROCESS_QUERY_INFORMATION = 0x0400;
    public const uint PROCESS_QUERY_LIMITED_INFORMATION = 0x1000;
    public const uint PROCESS_VM_READ = 0x0010;

    // ---- VirtualQueryEx --------------------------------------------------
    public const uint MEM_COMMIT = 0x1000;
    public const uint MEM_PRIVATE = 0x20000;
    public const uint MEM_MAPPED = 0x40000;
    public const uint MEM_IMAGE = 0x1000000;
    public const uint PAGE_NOACCESS = 0x01;
    public const uint PAGE_GUARD = 0x100;
    public const uint PAGE_READONLY = 0x02;
    public const uint PAGE_READWRITE = 0x04;
    public const uint PAGE_WRITECOPY = 0x08;
    public const uint PAGE_EXECUTE = 0x10;
    public const uint PAGE_EXECUTE_READ = 0x20;
    public const uint PAGE_EXECUTE_READWRITE = 0x40;
    public const uint PAGE_EXECUTE_WRITECOPY = 0x80;

    // ---- Toolhelp32 ------------------------------------------------------
    public const uint TH32CS_SNAPMODULE = 0x00000008;
    public const uint TH32CS_SNAPMODULE32 = 0x00000010;
    public const uint TH32CS_SNAPPROCESS = 0x00000002;
    public const uint MAX_PATH = 260;
    public const uint LIST_MODULES_ALL = 0x03;

    public const int ATTACH_PARENT_PROCESS = -1;

    [StructLayout(LayoutKind.Sequential)]
    public struct MEMORY_BASIC_INFORMATION64
    {
        public ulong BaseAddress;
        public ulong AllocationBase;
        public uint AllocationProtect;
        public uint __alignment1;
        public ulong RegionSize;
        public uint State;
        public uint Protect;
        public uint Type;
        public uint __alignment2;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct MODULEENTRY32W
    {
        public uint dwSize;
        public uint th32ModuleID;
        public uint th32ProcessID;
        public uint GlblcntUsage;
        public uint ProccntUsage;
        public IntPtr modBaseAddr;
        public uint modBaseSize;
        public IntPtr hModule;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
        public string szModule;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
        public string szExePath;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct PROCESSENTRY32W
    {
        public uint dwSize;
        public uint cntUsage;
        public uint th32ProcessID;
        public IntPtr th32DefaultHeapID;
        public uint th32ModuleID;
        public uint cntThreads;
        public uint th32ParentProcessID;
        public int pcPriClassBase;
        public uint dwFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
        public string szExeFile;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, int dwProcessId);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool CloseHandle(IntPtr hObject);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, IntPtr lpBuffer,
        IntPtr nSize, out IntPtr lpNumberOfBytesRead);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr VirtualQueryEx(IntPtr hProcess, IntPtr lpAddress,
        out MEMORY_BASIC_INFORMATION64 lpBuffer, IntPtr dwLength);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr CreateToolhelp32Snapshot(uint dwFlags, uint th32ProcessID);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool Module32FirstW(IntPtr hSnapshot, ref MODULEENTRY32W lpme);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool Module32NextW(IntPtr hSnapshot, ref MODULEENTRY32W lpme);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool Process32FirstW(IntPtr hSnapshot, ref PROCESSENTRY32W lppe);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool Process32NextW(IntPtr hSnapshot, ref PROCESSENTRY32W lppe);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWow64Process(IntPtr hProcess, [MarshalAs(UnmanagedType.Bool)] out bool wow64);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool AttachConsole(int dwProcessId);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool AllocConsole();

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool FreeConsole();

    [DllImport("shell32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern IntPtr ShellExecuteW(IntPtr hwnd, string lpOperation, string lpFile,
        string lpParameters, string lpDirectory, int nShowCmd);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetProcessDPIAware();

    /// <summary>把 Win32 错误码翻译成可读文本（用于日志与界面提示）。</summary>
    public static string DescribeError(int code)
    {
        try { return new System.ComponentModel.Win32Exception(code).Message; }
        catch { return "Win32 错误 " + code; }
    }

    public static string Gbk(uint value)
    {
        Span<byte> b = stackalloc byte[4];
        b[0] = (byte)(value & 0xFF);
        b[1] = (byte)((value >> 8) & 0xFF);
        b[2] = (byte)((value >> 16) & 0xFF);
        b[3] = (byte)((value >> 24) & 0xFF);
        return Encoding.ASCII.GetString(b);
    }

    public static uint FromGbk(string fourChars)
    {
        uint v = 0;
        for (int i = 0; i < 4 && i < fourChars.Length; i++) v |= (uint)fourChars[i] << (8 * i);
        return v;
    }
}
