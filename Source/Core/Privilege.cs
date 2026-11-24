using System.Runtime.InteropServices;

namespace War3DeathSettlement.Core;

/// <summary>
/// 进程令牌里的"特权"（privilege）。这里只用它来尝试启用 <c>SeDebugPrivilege</c>。
/// <para>
/// <b>必须先搞清楚它能治什么、不能治什么</b>，否则会白折腾：
/// </para>
/// <list type="bullet">
/// <item>
/// <b>能治：DACL / 属主</b>。目标进程由别的用户、平台服务（SYSTEM）拉起时，
/// 它的默认 DACL 里根本没有我们，<c>OpenProcess</c> 直接 <c>ERROR_ACCESS_DENIED(5)</c>。
/// 启用 <c>SeDebugPrivilege</c> 后，内核在访问检查里会**跳过 DACL 拒绝**，于是能打开。
/// </item>
/// <item>
/// <b>不能治：完整性级别（MIC）</b>。强制完整性检查是独立于 DACL 和特权的一道关，
/// 只认令牌的 IL。所以"游戏 High、我们 Medium"时，即使 SeDebug 已启用，
/// <c>PROCESS_VM_WRITE|CREATE_THREAD</c> 照样被拒 —— 那种情况只能提权。
/// </item>
/// </list>
/// <para>
/// 另一个坑：<c>AdjustTokenPrivileges</c> 在"令牌里根本没有这个特权"时**返回 TRUE**，
/// 必须再查 <c>GetLastError()==ERROR_NOT_ALL_ASSIGNED(1300)</c> 才知道没生效。
/// 未提权的进程正是这个状态（UAC 过滤令牌把管理员特权剥掉了），所以 1300 = "你还没提权"。
/// </para>
/// </summary>
public static class Privilege
{
    private const uint TOKEN_ADJUST_PRIVILEGES = 0x0020;
    private const uint SE_PRIVILEGE_ENABLED = 0x00000002;
    private const int ERROR_NOT_ALL_ASSIGNED = 1300;

    [StructLayout(LayoutKind.Sequential)]
    private struct LUID
    {
        public uint LowPart;
        public int HighPart;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct LUID_AND_ATTRIBUTES
    {
        public LUID Luid;
        public uint Attributes;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct TOKEN_PRIVILEGES
    {
        public uint PrivilegeCount;
        public LUID_AND_ATTRIBUTES Privilege;
    }

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetCurrentProcess();

    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool LookupPrivilegeValue(string? lpSystemName, string lpName, out LUID lpLuid);

    [DllImport("advapi32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool AdjustTokenPrivileges(IntPtr tokenHandle, [MarshalAs(UnmanagedType.Bool)] bool disableAllPrivileges,
        ref TOKEN_PRIVILEGES newState, int bufferLength, IntPtr previousState, IntPtr returnLength);

    /// <summary>给界面/日志用的一句话：本进程现在有没有 SeDebugPrivilege。仅在启用成功后有意义。</summary>
    public static string DebugState { get; private set; } = "未尝试";

    /// <summary>启用 <c>SeDebugPrivilege</c>。成功返回 null，失败返回原因（可直接进日志/横幅）。</summary>
    public static string? EnableSeDebug() => Enable("SeDebugPrivilege", out _);

    /// <summary>启用 <c>SeDebugPrivilege</c>，并记下状态。</summary>
    public static string? EnableSeDebugTracked()
    {
        string? r = Enable("SeDebugPrivilege", out bool held);
        DebugState = r == null ? "已启用" : held ? "启用失败" : "未持有（未提权）";
        return r;
    }

    private static string? Enable(string name, out bool held)
    {
        held = false;
        if (!Native.OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | Native.TOKEN_QUERY, out IntPtr token))
            return "OpenProcessToken 失败：" + Native.DescribeError(Marshal.GetLastWin32Error());
        try
        {
            if (!LookupPrivilegeValue(null, name, out LUID luid))
                return $"找不到特权 {name}：" + Native.DescribeError(Marshal.GetLastWin32Error());

            var tp = new TOKEN_PRIVILEGES
            {
                PrivilegeCount = 1,
                Privilege = new LUID_AND_ATTRIBUTES { Luid = luid, Attributes = SE_PRIVILEGE_ENABLED },
            };

            // 先把 last error 清零：AdjustTokenPrivileges 成功时不会重置它，
            // 残留的 1300 会被误读成"没拿到特权"。
            Marshal.SetLastPInvokeError(0);
            if (!AdjustTokenPrivileges(token, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero))
                return "AdjustTokenPrivileges 失败：" + Native.DescribeError(Marshal.GetLastWin32Error());

            int err = Marshal.GetLastPInvokeError();
            if (err == ERROR_NOT_ALL_ASSIGNED)
            {
                // 注意：这里 API 返回的是 TRUE，只有 GetLastError 才看得出来。
                held = false;
                return "令牌里没有该特权（未提权；UAC 过滤令牌的正常状态）";
            }
            if (err != 0) return "AdjustTokenPrivileges 返回成功但 last error=" + err;

            held = true;
            return null;
        }
        finally { Native.CloseHandle(token); }
    }
}
