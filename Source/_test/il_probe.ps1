# il_probe.ps1 -- who can inject into whom?
#
# Prints, for each selected process: integrity level (IL), bitness, and whether
# THIS process is allowed to get the access rights injection needs.
#
# Why this matters:
#   * Reading another process only needs PROCESS_VM_READ. That works ACROSS
#     integrity levels: a Medium process can read a High process.
#   * Injecting needs PROCESS_VM_WRITE | PROCESS_CREATE_THREAD. Those are WRITE
#     rights, and Mandatory Integrity Control blocks write-up: a lower-IL
#     process asking for them on a higher-IL target gets ERROR_ACCESS_DENIED (5)
#     from the kernel -- regardless of DACL and regardless of whether the
#     account is in the Administrators group.
#   * So "injection fails at OpenProcess with err=5" means: raise the injector's
#     IL (run as administrator), or lower the game's IL (start it unelevated).
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File il_probe.ps1
#   powershell -ExecutionPolicy Bypass -File il_probe.ps1 -ProcessId 1234,5678
#   powershell -ExecutionPolicy Bypass -File il_probe.ps1 -Name war3,dzwar3
#
# Exit code: 0 always (it is a report, not a gate).
#
# ASCII only (Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI).

[CmdletBinding()]
param(
    # Kept as string[] on purpose: with -File, PowerShell passes "1,2,3" as ONE
    # string, so int[] binding fails.  We split it ourselves below.
    [string[]]$ProcessId,
    [string[]]$Name = @('war3', 'War3', 'dzwar3', 'War3Trainer', 'War3DeathSettlement')
)

$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class IlProbe
{
    [DllImport("kernel32.dll", SetLastError = true)] static extern IntPtr OpenProcess(uint a, bool ih, int pid);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool CloseHandle(IntPtr h);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool IsWow64Process(IntPtr h, out bool wow);
    [DllImport("advapi32.dll", SetLastError = true)] static extern bool OpenProcessToken(IntPtr h, uint a, out IntPtr t);
    [DllImport("advapi32.dll", SetLastError = true)] static extern bool GetTokenInformation(IntPtr t, int c, IntPtr b, int l, out int r);
    [DllImport("kernel32.dll")] static extern uint GetCurrentProcessId();

    public static int LastError;

    public static int SelfPid() { return (int)GetCurrentProcessId(); }

    // 0 = unknown, 1 = Low, 2 = Medium, 3 = MediumPlus, 4 = High, 5 = System
    public static int Rank(int pid)
    {
        LastError = 0;
        IntPtr h = OpenProcess(0x1000, false, pid);          // PROCESS_QUERY_LIMITED_INFORMATION
        if (h == IntPtr.Zero) h = OpenProcess(0x0400, false, pid);   // PROCESS_QUERY_INFORMATION
        if (h == IntPtr.Zero) { LastError = Marshal.GetLastWin32Error(); return 0; }
        try
        {
            IntPtr tok;
            if (!OpenProcessToken(h, 8, out tok)) { LastError = Marshal.GetLastWin32Error(); return 0; }
            try
            {
                int need;
                GetTokenInformation(tok, 25, IntPtr.Zero, 0, out need);   // TokenIntegrityLevel
                if (need <= 0) { LastError = Marshal.GetLastWin32Error(); return 0; }
                IntPtr buf = Marshal.AllocHGlobal(need);
                try
                {
                    if (!GetTokenInformation(tok, 25, buf, need, out need)) { LastError = Marshal.GetLastWin32Error(); return 0; }
                    IntPtr sid = Marshal.ReadIntPtr(buf);      // TOKEN_MANDATORY_LABEL.Label.Sid
                    if (sid == IntPtr.Zero) return 0;
                    int n = Marshal.ReadByte(sid, 1);          // SubAuthorityCount
                    if (n <= 0) return 0;
                    uint rid = (uint)Marshal.ReadInt32(sid, 8 + (n - 1) * 4);   // last subauthority
                    if (rid == 0x1000) return 1;
                    if (rid == 0x2000) return 2;
                    if (rid == 0x2100) return 3;
                    if (rid == 0x3000) return 4;
                    if (rid == 0x4000) return 5;
                    return 0;
                }
                finally { Marshal.FreeHGlobal(buf); }
            }
            finally { CloseHandle(tok); }
        }
        finally { CloseHandle(h); }
    }

    public static string RankName(int r)
    {
        if (r == 1) return "Low";
        if (r == 2) return "Medium";
        if (r == 3) return "MediumPlus";
        if (r == 4) return "High";
        if (r == 5) return "System";
        return "unknown";
    }

    // Target bitness as seen from here: a WOW64 process reports x86.
    public static string Bits(int pid)
    {
        IntPtr h = OpenProcess(0x1000, false, pid);
        if (h == IntPtr.Zero) return "?";
        try
        {
            bool wow;
            if (!IsWow64Process(h, out wow)) return "?";
            return wow ? "x86" : "x64";
        }
        finally { CloseHandle(h); }
    }

    // 0 = we can get the rights injection needs; otherwise the Win32 error.
    public static int InjectRight(int pid)
    {
        IntPtr h = OpenProcess(0x1F0FFF, false, pid);   // PROCESS_ALL_ACCESS
        if (h == IntPtr.Zero) return Marshal.GetLastWin32Error();
        CloseHandle(h);
        return 0;
    }
}
'@

$selfPid = [IlProbe]::SelfPid()
$selfRank = [IlProbe]::Rank($selfPid)
$thisShell = "this shell   : PID {0}  {1}" -f $selfPid, [IlProbe]::RankName($selfRank)
$thisShell
''

$ids = @()
if ($ProcessId) {
    foreach ($chunk in $ProcessId) {
        foreach ($piece in ($chunk -split '[,;\s]+')) {
            if ($piece -match '^\d+$') { $ids += [int]$piece }
        }
    }
}
else {
    $wanted = @()
    foreach ($chunk in $Name) { $wanted += @($chunk -split '[,;\s]+' | Where-Object { $_ }) }
    $ids = @(Get-Process -ErrorAction SilentlyContinue |
             Where-Object { $wanted -contains $_.ProcessName } |
             Sort-Object ProcessName |
             Select-Object -ExpandProperty Id)
}

if (-not $ids -or $ids.Count -eq 0) {
    'no matching process.  pass -ProcessId <pid> or -Name <exe-without-.exe>'
    exit 0
}

$rows = @()
foreach ($id in $ids) {
    $p = Get-Process -Id $id -ErrorAction SilentlyContinue
    if (-not $p) { continue }

    $rank = [IlProbe]::Rank($id)
    $rankErr = [IlProbe]::LastError
    $il = [IlProbe]::RankName($rank)
    if ($rank -eq 0) { $il = "unknown(err=$rankErr)" }

    $err = [IlProbe]::InjectRight($id)
    if ($err -eq 0) { $verdict = 'OK' }
    elseif ($err -eq 5) { $verdict = 'DENIED(5)' }
    else { $verdict = "FAIL($err)" }

    $rows += [pscustomobject]@{
        PID     = $id
        Process = $p.ProcessName
        IL      = $il
        Bits    = [IlProbe]::Bits($id)
        Inject  = $verdict
    }
}

$rows | Format-Table -AutoSize

# Explain the verdicts, so the table is not just numbers.
foreach ($r in $rows) {
    if ($r.Inject -eq 'OK') { continue }
    if ($r.IL -like 'unknown*') {
        "PID {0} {1}: cannot even query the process ({2}).  Likely started by another user / session, or protected." -f $r.PID, $r.Process, $r.IL
        continue
    }
    if ($selfRank -lt [IlProbe]::Rank($r.PID)) {
        "PID {0} {1}: target is higher IL than this shell -> restart the injector as administrator." -f $r.PID, $r.Process
    }
    else {
        "PID {0} {1}: same or lower IL but still denied -> DACL / different owner, try SeDebugPrivilege." -f $r.PID, $r.Process
    }
}

''
'note: bitness must match too -- a 32-bit injector cannot LoadLibrary into a 64-bit target.'
