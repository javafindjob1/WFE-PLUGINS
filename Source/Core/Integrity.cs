using System.Runtime.InteropServices;

namespace War3DeathSettlement.Core;

/// <summary>
/// Windows 强制完整性控制（Mandatory Integrity Control）里的完整性级别。
/// <para>
/// 为什么关心它：本软件平时的读数只需要 <c>PROCESS_VM_READ | PROCESS_QUERY_LIMITED_INFORMATION</c>，
/// 从普通权限（Medium）读管理员权限（High）的游戏**是允许的**（读是"向下兼容"的）。
/// 但注入 ddh.dll 要 <c>PROCESS_VM_WRITE | PROCESS_CREATE_THREAD</c>，这两个是**写**权限，
/// 低完整性级别进程向高完整性级别进程申请写，会被内核直接拒绝并返回
/// <c>ERROR_ACCESS_DENIED(5)</c> —— 注意这跟 DACL 无关，也跟"当前账号在不在管理员组"无关。
/// </para>
/// <para>
/// 所以"普通权限注入不进去"的正确判断方式是**比两边的 IL**，而不是判断 IsInRole(Administrator)
/// （UAC 过滤令牌下 IsInRole 恒为 false，会把"已经是管理员只是被过滤"误判成"不是管理员"）。
/// </para>
/// </summary>
public enum IntegrityLevel : uint
{
    /// <summary>读不出来（进程已退出、受保护进程、或令牌查询失败）。</summary>
    Unknown = 0xFFFF,
    Low = 0x1000,
    Medium = 0x2000,
    MediumPlus = 0x2100,
    High = 0x3000,
    System = 0x4000,
}

/// <summary>读写进程完整性级别（只查询令牌，不改任何安全设置）。</summary>
public static class Integrity
{
    /// <summary>本进程的完整性级别（普通双击启动 = Medium，以管理员身份运行 = High）。</summary>
    public static IntegrityLevel Self => OfProcess(unchecked((int)Native.GetCurrentProcessId()), out _);

    /// <summary>目标进程的完整性级别；失败返回 <see cref="IntegrityLevel.Unknown"/> 并在 error 里给出 Win32 错误码。</summary>
    public static IntegrityLevel OfProcess(int pid, out int error)
    {
        error = 0;
        IntPtr h = Native.OpenProcess(Native.PROCESS_QUERY_LIMITED_INFORMATION, false, pid);
        if (h == IntPtr.Zero)
        {
            // 老系统/特殊进程可能没有 QUERY_LIMITED：退一步用 QUERY_INFORMATION 再试。
            h = Native.OpenProcess(Native.PROCESS_QUERY_INFORMATION, false, pid);
            if (h == IntPtr.Zero) { error = Marshal.GetLastWin32Error(); return IntegrityLevel.Unknown; }
        }
        try { return OfProcessHandle(h, out error); }
        finally { Native.CloseHandle(h); }
    }

    private static IntegrityLevel OfProcessHandle(IntPtr hProcess, out int error)
    {
        error = 0;
        if (!Native.OpenProcessToken(hProcess, Native.TOKEN_QUERY, out IntPtr token))
        {
            error = Marshal.GetLastWin32Error();
            return IntegrityLevel.Unknown;
        }
        try
        {
            // 先问长度（这一步按文档会返回 false + ERROR_INSUFFICIENT_BUFFER，属正常）。
            Native.GetTokenInformation(token, Native.TokenIntegrityLevel, IntPtr.Zero, 0, out int need);
            if (need <= 0) { error = Marshal.GetLastWin32Error(); return IntegrityLevel.Unknown; }

            IntPtr buf = Marshal.AllocHGlobal(need);
            try
            {
                if (!Native.GetTokenInformation(token, Native.TokenIntegrityLevel, buf, need, out _))
                {
                    error = Marshal.GetLastWin32Error();
                    return IntegrityLevel.Unknown;
                }

                // TOKEN_MANDATORY_LABEL { SID_AND_ATTRIBUTES Label; } → Label.Sid 指向一个 SID，
                // 完整性级别 = 该 SID 的**最后一个子权威**（RID）。
                IntPtr sid = Marshal.ReadIntPtr(buf);
                if (sid == IntPtr.Zero) return IntegrityLevel.Unknown;
                int subCount = Marshal.ReadByte(sid, 1);
                if (subCount <= 0) return IntegrityLevel.Unknown;

                uint rid = unchecked((uint)Marshal.ReadInt32(sid, 8 + (subCount - 1) * 4));
                return rid switch
                {
                    0x1000 => IntegrityLevel.Low,
                    0x2000 => IntegrityLevel.Medium,
                    0x2100 => IntegrityLevel.MediumPlus,
                    0x3000 => IntegrityLevel.High,
                    0x4000 => IntegrityLevel.System,
                    _ => IntegrityLevel.Unknown,
                };
            }
            finally { Marshal.FreeHGlobal(buf); }
        }
        catch (Exception ex)
        {
            error = ex.HResult;
            return IntegrityLevel.Unknown;
        }
        finally { Native.CloseHandle(token); }
    }

    /// <summary>
    /// 本进程是否**已提升**（High / System）。
    /// <para>
    /// 注意别写成 <c>Self &gt;= High</c>：<see cref="IntegrityLevel.Unknown"/> 的枚举值是 0xFFFF，
    /// 那样"读不出来"会被误判成"已经是管理员"。
    /// </para>
    /// </summary>
    public static bool IsSelfElevated
    {
        get
        {
            IntegrityLevel il = Self;
            return il == IntegrityLevel.High || il == IntegrityLevel.System;
        }
    }

    /// <summary>
    /// 本进程能不能往目标进程写内存 / 建远程线程（即能不能注入）：
    /// 要求本进程 IL ≥ 目标 IL。判不出来时返回 true（不拦，让注入器自己去报真错误）。
    /// </summary>
    public static bool CanInject(IntegrityLevel target)
    {
        IntegrityLevel self = Self;
        if (self == IntegrityLevel.Unknown || target == IntegrityLevel.Unknown) return true;
        return self >= target;
    }

    /// <summary>给界面/日志用的名字。</summary>
    public static string Name(IntegrityLevel il) => il switch
    {
        IntegrityLevel.Low => "低（Low）",
        IntegrityLevel.Medium => "普通（Medium）",
        IntegrityLevel.MediumPlus => "中高（Medium Plus）",
        IntegrityLevel.High => "管理员（High）",
        IntegrityLevel.System => "系统（System）",
        _ => "未知",
    };

    /// <summary>一句话说明两边差在哪（横幅/日志用）。</summary>
    public static string Diff(IntegrityLevel self, IntegrityLevel target) =>
        $"游戏 {Name(target)} / 本程序 {Name(self)}";
}
