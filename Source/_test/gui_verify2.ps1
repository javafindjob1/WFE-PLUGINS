# GUI verification #2: UIA-based assertions + screenshots.
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
    Write-Host "SHOT $Out"
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

function Get-WinElement([int]$ProcId) {
    $hwnd = [W32Shot]::FindMain($ProcId)
    return [System.Windows.Automation.AutomationElement]::FromHandle($hwnd)
}

function Find-ByControlType($root, $ctName) {
    $all = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
    $res = @()
    foreach ($e in $all) {
        if ($e.Current.ControlType.ProgrammaticName -eq $ctName) { $res += $e }
    }
    return ,$res
}

function Find-TopVisibleGrid($root) {
    $all = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
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

function Get-ColumnNames($grid) {
    $names = @()
    try {
        $tp = $grid.GetCurrentPattern([System.Windows.Automation.TablePattern]::Pattern)
        $headers = $tp.Current.GetColumnHeaders()
        foreach ($h in $headers) { $names += $h.Current.Name }
    } catch {
        $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::HeaderItem)
        $hs = $grid.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
        foreach ($h in $hs) { $names += $h.Current.Name }
    }
    return ,$names
}

function Get-RowCount($grid) {
    try {
        $gp = $grid.GetCurrentPattern([System.Windows.Automation.GridPattern]::Pattern)
        return $gp.Current.RowCount
    } catch {
        return -1
    }
}

function Get-SelectedTabName($root) {
    $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)
    $tabs = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
    foreach ($t in $tabs) {
        try {
            $sp = $t.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern)
            if ($sp.Current.IsSelected) { return $t.Current.Name }
        } catch { }
    }
    return ""
}

function Find-AddrHint($root) {
    $all = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
    foreach ($e in $all) {
        if ($e.Current.Name -like "只看*") { return $e }
    }
    return $null
}

function Find-ByName($root, $name) {
    $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $name)
    return $root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
}

function Click-Center($elem) {
    $r = $elem.Current.BoundingRectangle
    Invoke-Click ([int]($r.Left + $r.Width / 2)) ([int]($r.Top + $r.Height / 2))
}

# ---------------- scenario ----------------
$env:FAKE_UNITS='30'; $env:FAKE_HEAP_MB='0'; $env:FAKE_IMMORTAL='0'; $env:FAKE_AMP='150'
Remove-Item (Join-Path $fg "gv2_fake_out.log"), (Join-Path $fg "gv2_fake_err.log") -ErrorAction SilentlyContinue
$fake = Start-Process -FilePath (Join-Path $fg "fakewar3.exe") -ArgumentList "240" -WorkingDirectory $fg `
    -RedirectStandardOutput (Join-Path $fg "gv2_fake_out.log") -RedirectStandardError (Join-Path $fg "gv2_fake_err.log") -PassThru -WindowStyle Hidden
Write-Host "FAKE PID=$($fake.Id)"
Start-Sleep -Seconds 1

Remove-Item (Join-Path $bin "gv2_gui_out.log"), (Join-Path $bin "gv2_gui_err.log") -ErrorAction SilentlyContinue
$gui = Start-Process -FilePath (Join-Path $bin "War3DeathSettlement.exe") `
    -ArgumentList "--name","fakewar3","--force-version","1.27.0.52240" -WorkingDirectory $bin `
    -RedirectStandardOutput (Join-Path $bin "gv2_gui_out.log") -RedirectStandardError (Join-Path $bin "gv2_gui_err.log") -PassThru -WindowStyle Normal
Write-Host "GUI PID=$($gui.Id)"

$deadline = (Get-Date).AddSeconds(25)
$winReady = $false
while ((Get-Date) -lt $deadline) {
    if (-not (Get-Process -Id $gui.Id -ErrorAction SilentlyContinue)) { Write-Host "GUI exited early"; break }
    if ([W32Shot]::FindMain($gui.Id) -ne [IntPtr]::Zero) { $winReady = $true; break }
    Start-Sleep -Milliseconds 300
}
if (-not $winReady) { Write-Host "GUI window did not appear"; Stop-Process -Id $fake.Id -Force -ErrorAction SilentlyContinue; exit 1 }
Write-Host "GUI window appeared; waiting 20s..."
Start-Sleep -Seconds 20

$root = Get-WinElement $gui.Id

# 1) settle page: column headers
$grid = Find-TopVisibleGrid $root
$cols = Get-ColumnNames $grid
Write-Host ("SETTLE_COLCOUNT=" + $cols.Count)
Write-Host ("SETTLE_COLS=" + ($cols -join '|'))
Write-Host ("HAS_伤害统计=" + [bool]($cols -contains "伤害统计"))
Shot-Pid $gui.Id (Join-Path $shot "shot1_settle.png")

# read hook grid all-count (switch to 伤害事件 tab first)
$tabHook = Find-ByName $root "伤害事件"
$hookAll = -1
if ($tabHook) {
    Click-Center $tabHook
    Start-Sleep -Milliseconds 800
    $hg = Find-TopVisibleGrid (Get-WinElement $gui.Id)
    $hookAll = Get-RowCount $hg
    Write-Host "HOOK_ALL_COUNT=$hookAll"
    # back to settle tab
    $ts = Find-ByName (Get-WinElement $gui.Id) "死亡结算"
    if ($ts) { Click-Center $ts; Start-Sleep -Milliseconds 700 }
}

# 2) double-click settle row 0
Focus-Win $gui.Id
$grid = Find-TopVisibleGrid (Get-WinElement $gui.Id)
$r = $grid.Current.BoundingRectangle
Invoke-DoubleClick ([int]($r.Left + 60)) ([int]($r.Top + 37))
Start-Sleep -Milliseconds 900
$root = Get-WinElement $gui.Id
Write-Host ("AFTER_SETTLE_TAB=" + (Get-SelectedTabName $root))
$hint = Find-AddrHint $root
Write-Host ("AFTER_SETTLE_HINT=" + $(if ($hint) { $hint.Current.Name } else { "<none>" }))
$hg2 = Find-TopVisibleGrid $root
Write-Host ("HOOK_FILTERED_COUNT=" + (Get-RowCount $hg2))
Shot-Pid $gui.Id (Join-Path $shot "shot2_jump_settle.png")

# 3) back to settle tab, scroll down, double-click last (live) row
$ts2 = Find-ByName (Get-WinElement $gui.Id) "死亡结算"
if ($ts2) { Click-Center $ts2; Start-Sleep -Milliseconds 700 }
$grid3 = Find-TopVisibleGrid (Get-WinElement $gui.Id)
if ($grid3) {
    $r3 = $grid3.Current.BoundingRectangle
    Invoke-Wheel ([int]($r3.Left + $r3.Width/2)) ([int]($r3.Top + $r3.Height/2)) 40
    Start-Sleep -Milliseconds 600
    Focus-Win $gui.Id
    Invoke-DoubleClick ([int]($r3.Left + 60)) ([int]($r3.Bottom - 11))
    Start-Sleep -Milliseconds 900
}
$root = Get-WinElement $gui.Id
Write-Host ("AFTER_LIVE_TAB=" + (Get-SelectedTabName $root))
$hint2 = Find-AddrHint $root
Write-Host ("AFTER_LIVE_HINT=" + $(if ($hint2) { $hint2.Current.Name } else { "<none>" }))
Shot-Pid $gui.Id (Join-Path $shot "shot3_jump_live.png")

# 4) click 清除筛选
$btn = Find-ByName (Get-WinElement $gui.Id) "清除筛选"
if ($btn) { Click-Center $btn; Start-Sleep -Milliseconds 900 }
$root = Get-WinElement $gui.Id
$hint3 = Find-AddrHint $root
Write-Host ("AFTER_CLEAR_HINT=" + $(if ($hint3) { $hint3.Current.Name } else { "<none>" }))
$hg4 = Find-TopVisibleGrid $root
Write-Host ("HOOK_AFTER_CLEAR_COUNT=" + (Get-RowCount $hg4))
Shot-Pid $gui.Id (Join-Path $shot "shot4_clear.png")

Write-Host "DONE2"
Stop-Process -Id $fake.Id -Force -ErrorAction SilentlyContinue
Stop-Process -Id $gui.Id -Force -ErrorAction SilentlyContinue
