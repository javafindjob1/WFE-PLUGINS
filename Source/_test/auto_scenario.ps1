# fake-war3 GUI scenario automation (ASCII only). Usage:
#   pwsh -File auto_scenario.ps1 -Scenario A|B|C
param(
    [Parameter(Mandatory=$true)][ValidateSet('A','B','C')][string]$Scenario
)
$ErrorActionPreference = 'Stop'

$test = $PSScriptRoot
$root = Split-Path -Parent $test   # DeathSettlement
$fg   = Join-Path $test "fakegame"
$bin  = Join-Path $root "bin\Release\net10.0-windows"

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W32Shot {
  [StructLayout(LayoutKind.Sequential)]
  public struct RECT { public int Left, Top, Right, Bottom; }
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdc, uint flags);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmd);
  [DllImport("user32.dll")] public static extern bool UpdateWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
  public delegate bool EnumProc(IntPtr hWnd, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);

  public static IntPtr FindMain(int targetPid) {
    IntPtr best = IntPtr.Zero; long bestArea = 0;
    EnumWindows(delegate(IntPtr h, IntPtr l) {
      uint pid; GetWindowThreadProcessId(h, out pid);
      if (pid != targetPid) return true;
      RECT r; GetWindowRect(h, out r);
      long area = (long)(r.Right - r.Left) * (long)(r.Bottom - r.Top);
      if (area > bestArea) { bestArea = area; best = h; }
      return true;
    }, IntPtr.Zero);
    return best;
  }
}
"@

function Shot-Pid([int]$ProcId, [string]$Out) {
    $p = Get-Process -Id $ProcId -ErrorAction Stop
    $hwnd = [W32Shot]::FindMain($ProcId)
    if ($hwnd -eq [IntPtr]::Zero) { throw "PID $ProcId has no top-level window" }
    [W32Shot]::ShowWindow($hwnd, 9) | Out-Null   # SW_RESTORE
    [W32Shot]::ShowWindow($hwnd, 5) | Out-Null   # SW_SHOW
    [W32Shot]::SetForegroundWindow($hwnd) | Out-Null
    [W32Shot]::UpdateWindow($hwnd) | Out-Null
    Start-Sleep -Milliseconds 600
    $r = New-Object W32Shot+RECT
    [W32Shot]::GetWindowRect($hwnd, [ref]$r) | Out-Null
    $w = $r.Right - $r.Left; $h = $r.Bottom - $r.Top
    if ($w -le 0 -or $h -le 0) { $w = 1280; $h = 800 }
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $hdc = $g.GetHdc()
    [W32Shot]::PrintWindow($hwnd, $hdc, 2) | Out-Null
    $g.ReleaseHdc($hdc); $g.Dispose()
    $bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
    Write-Host "SHOT $Out (${w}x${h})"
}

function Start-Fake([string]$suffix, [string]$units, [string]$heap, [string]$immortal, [string]$amp) {
    $env:FAKE_UNITS=$units; $env:FAKE_HEAP_MB=$heap; $env:FAKE_IMMORTAL=$immortal; $env:FAKE_AMP=$amp
    $out = Join-Path $fg "auto_${suffix}_out.log"; $err = Join-Path $fg "auto_${suffix}_err.log"
    Remove-Item $out,$err -ErrorAction SilentlyContinue
    $p = Start-Process -FilePath (Join-Path $fg "fakewar3.exe") -ArgumentList "240" -WorkingDirectory $fg `
        -RedirectStandardOutput $out -RedirectStandardError $err -PassThru -WindowStyle Hidden
    Write-Host "FAKE $suffix PID=$($p.Id)"
    return $p.Id
}

function Start-Gui([string]$suffix) {
    $out = Join-Path $bin "auto_${suffix}_gui_out.log"; $err = Join-Path $bin "auto_${suffix}_gui_err.log"
    Remove-Item $out,$err -ErrorAction SilentlyContinue
    $p = Start-Process -FilePath (Join-Path $bin "War3DeathSettlement.exe") `
        -ArgumentList "--name","fakewar3","--force-version","1.27.0.52240" -WorkingDirectory $bin `
        -RedirectStandardOutput $out -RedirectStandardError $err -PassThru -WindowStyle Normal
    Write-Host "GUI $suffix PID=$($p.Id)"
    return $p.Id
}

function Wait-GuiWindow([int]$ProcId, [int]$seconds) {
    $deadline = (Get-Date).AddSeconds($seconds)
    while ((Get-Date) -lt $deadline) {
        $p = Get-Process -Id $ProcId -ErrorAction SilentlyContinue
        if (-not $p) { throw "GUI $ProcId exited" }
        if ([W32Shot]::FindMain($ProcId) -ne [IntPtr]::Zero) { return }
        Start-Sleep -Milliseconds 300
    }
    throw "GUI $ProcId window did not appear"
}

function Get-LatestDss {
    return Get-ChildItem (Join-Path $bin "logs\dss-*.log") | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

switch ($Scenario) {
  'A' {
    $fid = Start-Fake "A1" "20" "0" "0" "150"
    Start-Sleep -Seconds 1
    $gid = Start-Gui "A"
    Wait-GuiWindow $gid 20
    Write-Host "GUI A window appeared"
    Start-Sleep -Seconds 8
    Shot-Pid $gid (Join-Path $test "scenario_A_connected.png")
    $log = (Get-LatestDss).FullName
    Write-Host "CONNECTED_LOG=$log"

    Stop-Process -Id $fid -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    $guiAlive = [bool](Get-Process -Id $gid -ErrorAction SilentlyContinue)
    Write-Host "GUI_ALIVE_AFTER_KILL=$guiAlive"
    Shot-Pid $gid (Join-Path $test "scenario_A_exited.png")

    $fid2 = Start-Fake "A2" "20" "0" "0" "150"
    Start-Sleep -Seconds 10
    $log3 = (Get-LatestDss).FullName
    Write-Host "RECONNECTED_LOG=$log3"
    Shot-Pid $gid (Join-Path $test "scenario_A_reconnected.png")

    Stop-Process -Id $fid2 -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $gid -Force -ErrorAction SilentlyContinue
    Write-Host "SCENARIO A DONE"
  }
  'B' {
    $fid = Start-Fake "B" "20" "0" "0" "150"
    Start-Sleep -Seconds 1
    $gid = Start-Gui "B"
    Wait-GuiWindow $gid 20
    Start-Sleep -Seconds 8
    $log = (Get-LatestDss).FullName
    Write-Host "CONNECTED_LOG=$log"

    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName UIAutomationTypes
    $root = [System.Windows.Automation.AutomationElement]::RootElement
    $findName = -join ([char]0x67E5, [char]0x627E, [char]0x6E38, [char]0x620F)   # find-game button
    $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $findName)
    $btn = $root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
    if ($btn) {
        $pat = $btn.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
        $pat.Invoke()
        Write-Host "CLICKED_FIND=yes"
    } else {
        Write-Host "CLICKED_FIND=no(UIA not found)"
    }
    Start-Sleep -Milliseconds 700
    Shot-Pid $gid (Join-Path $test "scenario_B_cleared.png")

    Stop-Process -Id $fid -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $gid -Force -ErrorAction SilentlyContinue
    Write-Host "SCENARIO B DONE"
  }
  'C' {
    $env:DSS_IDLE_MINUTES = "0.05"
    $fid = Start-Fake "C" "20" "0" "1" "150"
    Start-Sleep -Seconds 1
    $gid = Start-Gui "C"
    Wait-GuiWindow $gid 20
    Start-Sleep -Seconds 15
    $log = (Get-LatestDss).FullName
    Write-Host "IDLE_LOG=$log"
    Shot-Pid $gid (Join-Path $test "scenario_C_idle.png")

    Stop-Process -Id $fid -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $gid -Force -ErrorAction SilentlyContinue
    Remove-Item Env:DSS_IDLE_MINUTES -ErrorAction SilentlyContinue
    Write-Host "SCENARIO C DONE"
  }
}
