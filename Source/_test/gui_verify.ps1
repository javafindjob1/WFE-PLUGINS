# GUI verification: double-click jump to 伤害事件 page with address filter.
# Usage: pwsh -File gui_verify.ps1
$ErrorActionPreference = 'Continue'

$test = $PSScriptRoot
$root = Split-Path -Parent $test
$fg   = Join-Path $test "fakegame"
$bin  = Join-Path $root "bin\Release\net10.0-windows"
$shot = Join-Path $test "gui_verify"
New-Item -ItemType Directory -Force -Path $shot | Out-Null

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

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
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, int dwData, UIntPtr dwExtraInfo);
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
    $hwnd = [W32Shot]::FindMain($ProcId)
    if ($hwnd -eq [IntPtr]::Zero) { throw "PID $ProcId has no top-level window" }
    [W32Shot]::ShowWindow($hwnd, 9) | Out-Null
    [W32Shot]::ShowWindow($hwnd, 5) | Out-Null
    [W32Shot]::SetForegroundWindow($hwnd) | Out-Null
    [W32Shot]::UpdateWindow($hwnd) | Out-Null
    Start-Sleep -Milliseconds 700
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

function Focus-Win([int]$ProcId) {
    $hwnd = [W32Shot]::FindMain($ProcId)
    [W32Shot]::SetForegroundWindow($hwnd) | Out-Null
    Start-Sleep -Milliseconds 250
}

function Invoke-Click([int]$x, [int]$y) {
    [W32Shot]::SetCursorPos($x, $y) | Out-Null
    Start-Sleep -Milliseconds 60
    [W32Shot]::mouse_event(0x02, 0, 0, 0, [UIntPtr]::Zero)
    [W32Shot]::mouse_event(0x04, 0, 0, 0, [UIntPtr]::Zero)
}

function Invoke-DoubleClick([int]$x, [int]$y) {
    [W32Shot]::SetCursorPos($x, $y) | Out-Null
    Start-Sleep -Milliseconds 70
    [W32Shot]::mouse_event(0x02, 0, 0, 0, [UIntPtr]::Zero)
    [W32Shot]::mouse_event(0x04, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 60
    [W32Shot]::mouse_event(0x02, 0, 0, 0, [UIntPtr]::Zero)
    [W32Shot]::mouse_event(0x04, 0, 0, 0, [UIntPtr]::Zero)
}

function Invoke-Wheel([int]$x, [int]$y, [int]$notches) {
    [W32Shot]::SetCursorPos($x, $y) | Out-Null
    Start-Sleep -Milliseconds 50
    for ($i = 0; $i -lt $notches; $i++) {
        [W32Shot]::mouse_event(0x0800, 0, 0, -120, [UIntPtr]::Zero)
        Start-Sleep -Milliseconds 30
    }
}

function Find-Element([System.Windows.Automation.AutomationElement]$root, [string]$name) {
    $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $name)
    return $root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
}

function Get-WinElement([int]$ProcId) {
    $hwnd = [W32Shot]::FindMain($ProcId)
    return [System.Windows.Automation.AutomationElement]::FromHandle($hwnd)
}

function Find-SettleGrid([int]$ProcId) {
    $win = Get-WinElement $ProcId
    $all = $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
    $best = $null; $bestTop = 1e9
    foreach ($e in $all) {
        $ct = $e.Current.ControlType.ProgrammaticName
        if ($ct -notmatch 'DataGrid|Table') { continue }
        $r = $e.Current.BoundingRectangle
        if ($r.Width -le 50 -or $r.Height -le 50) { continue }
        if ($e.Current.IsOffscreen) { continue }
        if ($r.Top -lt $bestTop) { $best = $e; $bestTop = $r.Top }
    }
    return $best
}

function Click-ElementCenter($elem) {
    $r = $elem.Current.BoundingRectangle
    $x = [int]($r.Left + $r.Width / 2)
    $y = [int]($r.Top + $r.Height / 2)
    Invoke-Click $x $y
}

# ---------------- scenario ----------------
$env:FAKE_UNITS='30'; $env:FAKE_HEAP_MB='0'; $env:FAKE_IMMORTAL='0'; $env:FAKE_AMP='150'
Remove-Item (Join-Path $fg "gv_fake_out.log"), (Join-Path $fg "gv_fake_err.log") -ErrorAction SilentlyContinue
$fake = Start-Process -FilePath (Join-Path $fg "fakewar3.exe") -ArgumentList "240" -WorkingDirectory $fg `
    -RedirectStandardOutput (Join-Path $fg "gv_fake_out.log") -RedirectStandardError (Join-Path $fg "gv_fake_err.log") -PassThru -WindowStyle Hidden
Write-Host "FAKE PID=$($fake.Id)"
Start-Sleep -Seconds 1

Remove-Item (Join-Path $bin "gv_gui_out.log"), (Join-Path $bin "gv_gui_err.log") -ErrorAction SilentlyContinue
$gui = Start-Process -FilePath (Join-Path $bin "War3DeathSettlement.exe") `
    -ArgumentList "--name","fakewar3","--force-version","1.27.0.52240" -WorkingDirectory $bin `
    -RedirectStandardOutput (Join-Path $bin "gv_gui_out.log") -RedirectStandardError (Join-Path $bin "gv_gui_err.log") -PassThru -WindowStyle Normal
Write-Host "GUI PID=$($gui.Id)"

# wait for window
$deadline = (Get-Date).AddSeconds(25)
$winReady = $false
while ((Get-Date) -lt $deadline) {
    if (-not (Get-Process -Id $gui.Id -ErrorAction SilentlyContinue)) { Write-Host "GUI exited early"; break }
    if ([W32Shot]::FindMain($gui.Id) -ne [IntPtr]::Zero) { $winReady = $true; break }
    Start-Sleep -Milliseconds 300
}
if (-not $winReady) { Write-Host "GUI window did not appear"; exit 1 }
Write-Host "GUI window appeared; waiting for settlements + events..."
Start-Sleep -Seconds 20

# 1) settlement page screenshot (verify no 伤害统计 column)
Shot-Pid $gui.Id (Join-Path $shot "shot1_settle.png")

$grid = Find-SettleGrid $gui.Id
if ($null -eq $grid) {
    Write-Host "ERROR: settle grid not found via UIA"
    Shot-Pid $gui.Id (Join-Path $shot "shot_diag_nogrid.png")
    Stop-Process -Id $fake.Id -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $gui.Id -Force -ErrorAction SilentlyContinue
    exit 1
}
$r = $grid.Current.BoundingRectangle
Write-Host ("SETTLE GRID rect= L{0} T{1} R{2} B{3} W{4} H{5}" -f $r.Left, $r.Top, $r.Right, $r.Bottom, $r.Width, $r.Height)

Focus-Win $gui.Id
# double-click first settlement row (row 0)
Invoke-DoubleClick ([int]($r.Left + 60)) ([int]($r.Top + 37))
Start-Sleep -Milliseconds 900
Shot-Pid $gui.Id (Join-Path $shot "shot2_jump_settle.png")

# switch back to 死亡结算 tab
$win = Get-WinElement $gui.Id
$tabSettle = Find-Element $win "死亡结算"
if ($tabSettle) { Click-ElementCenter $tabSettle; Start-Sleep -Milliseconds 700 } else { Write-Host "WARN: 死亡结算 tab not found" }

# scroll settle grid to bottom and double-click last (live) row
$grid2 = Find-SettleGrid $gui.Id
if ($null -eq $grid2) { Write-Host "WARN: settle grid not found on 2nd pass" }
else {
    $r2 = $grid2.Current.BoundingRectangle
    $cx = [int]($r2.Left + $r2.Width / 2)
    $cy = [int]($r2.Top + $r2.Height / 2)
    Invoke-Wheel $cx $cy 40
    Start-Sleep -Milliseconds 600
    Focus-Win $gui.Id
    Invoke-DoubleClick ([int]($r2.Left + 60)) ([int]($r2.Bottom - 11))
    Start-Sleep -Milliseconds 900
}
Shot-Pid $gui.Id (Join-Path $shot "shot3_jump_live.png")

# click 清除筛选
$win3 = Get-WinElement $gui.Id
$btnClear = Find-Element $win3 "清除筛选"
if ($btnClear) { Click-ElementCenter $btnClear; Start-Sleep -Milliseconds 900 } else { Write-Host "WARN: 清除筛选 button not found" }
Shot-Pid $gui.Id (Join-Path $shot "shot4_clear.png")

Write-Host "DONE gui_verify"
Stop-Process -Id $fake.Id -Force -ErrorAction SilentlyContinue
Stop-Process -Id $gui.Id -Force -ErrorAction SilentlyContinue
