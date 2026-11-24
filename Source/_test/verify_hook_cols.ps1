# verify_hook_cols.ps1 -- run fakewar3 + GUI, seed the DdhRing with synthetic 0x017xxxxx events,
# then screenshot the 伤害事件 page and the double-click popup. ASCII-only on purpose.
$ErrorActionPreference = 'Stop'

$test = $PSScriptRoot
$root = Split-Path -Parent $test
$fg   = Join-Path $test "fakegame"
$bin  = Join-Path $root "bin\Release\net10.0-windows"
$lc   = Join-Path $test "layoutcheck\bin\Release\net10.0-windows\layoutcheck.exe"
$outdir = Join-Path $test "verify_hook"
New-Item -ItemType Directory -Force -Path $outdir | Out-Null

$TAB_HOOK   = -join (0x4F24,0x5BB3,0x4E8B,0x4EF6 | ForEach-Object { [char]$_ })   # 伤害事件
$TAB_SETTLE = -join (0x6B7B,0x4EA1,0x7ED3,0x7B97 | ForEach-Object { [char]$_ })   # 死亡结算

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W32V {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdc, uint flags);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmd);
  [DllImport("user32.dll")] public static extern bool UpdateWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint data, IntPtr extra);
  [DllImport("user32.dll")] public static extern int GetWindowTextW(IntPtr hWnd, System.Text.StringBuilder sb, int max);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
  public delegate bool EnumProc(IntPtr hWnd, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
  public static IntPtr FindMain(int pid) {
    IntPtr best = IntPtr.Zero; long area = 0;
    EnumWindows(delegate(IntPtr h, IntPtr l) {
      uint p; GetWindowThreadProcessId(h, out p);
      if (p != pid) return true;
      RECT r; GetWindowRect(h, out r);
      long a = (long)(r.Right - r.Left) * (long)(r.Bottom - r.Top);
      if (a > area) { area = a; best = h; } return true;
    }, IntPtr.Zero);
    return best;
  }
  public static string Title(IntPtr h) { var sb = new System.Text.StringBuilder(512); GetWindowTextW(h, sb, 512); return sb.ToString(); }
  public static IntPtr FindByTitle(int pid, string sub) {
    IntPtr found = IntPtr.Zero;
    EnumWindows(delegate(IntPtr h, IntPtr l) {
      uint p; GetWindowThreadProcessId(h, out p);
      if (p != pid) return true;
      if (!IsWindowVisible(h)) return true;
      if (Title(h).Contains(sub)) { found = h; return false; } return true;
    }, IntPtr.Zero);
    return found;
  }
  [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint flags);
  public static void DblClick(int x, int y) {
    SetCursorPos(x, y); System.Threading.Thread.Sleep(80);
    mouse_event(0x02,0,0,0,IntPtr.Zero); mouse_event(0x04,0,0,0,IntPtr.Zero);
    System.Threading.Thread.Sleep(90);
    mouse_event(0x02,0,0,0,IntPtr.Zero); mouse_event(0x04,0,0,0,IntPtr.Zero);
  }
}
"@

function Shot-Window([IntPtr]$hwnd, [string]$Out) {
    [W32V]::ShowWindow($hwnd, 9) | Out-Null; [W32V]::ShowWindow($hwnd, 5) | Out-Null
    [W32V]::SetForegroundWindow($hwnd) | Out-Null; [W32V]::UpdateWindow($hwnd) | Out-Null
    Start-Sleep -Milliseconds 700
    $r = New-Object W32V+RECT; [W32V]::GetWindowRect($hwnd, [ref]$r) | Out-Null
    $w = $r.Right - $r.Left; $h = $r.Bottom - $r.Top
    if ($w -le 0 -or $h -le 0) { $w = 1280; $h = 800 }
    $bmp = New-Object System.Drawing.Bitmap($w, $h); $g = [System.Drawing.Graphics]::FromImage($bmp)
    $hdc = $g.GetHdc(); [W32V]::PrintWindow($hwnd, $hdc, 2) | Out-Null; $g.ReleaseHdc($hdc); $g.Dispose()
    $bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
    Write-Host "SHOT $Out (${w}x${h})"
}

function Shot-Pid([int]$ProcId, [string]$Out) {
    $hwnd = [W32V]::FindMain($ProcId)
    if ($hwnd -eq [IntPtr]::Zero) { throw "no window for pid $ProcId" }
    Shot-Window $hwnd $Out
}

$env:FAKE_UNITS='30'; $env:FAKE_HEAP_MB='0'; $env:FAKE_IMMORTAL='0'; $env:FAKE_AMP='150'
$fo = Join-Path $fg "vh_fake_out.log"; $fe = Join-Path $fg "vh_fake_err.log"
Remove-Item $fo,$fe -ErrorAction SilentlyContinue
$fake = Start-Process -FilePath (Join-Path $fg "fakewar3.exe") -ArgumentList "300" -WorkingDirectory $fg `
    -RedirectStandardOutput $fo -RedirectStandardError $fe -PassThru -WindowStyle Hidden
Write-Host "FAKE PID=$($fake.Id)"
Start-Sleep -Seconds 2

$go = Join-Path $bin "vh_gui_out.log"; $ge = Join-Path $bin "vh_gui_err.log"
Remove-Item $go,$ge -ErrorAction SilentlyContinue
$gui = Start-Process -FilePath (Join-Path $bin "War3DeathSettlement.exe") `
    -ArgumentList "--name","fakewar3","--force-version","1.27.0.52240" -WorkingDirectory $bin `
    -RedirectStandardOutput $go -RedirectStandardError $ge -PassThru -WindowStyle Normal
Write-Host "GUI PID=$($gui.Id)"

$deadline = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $deadline) {
    if (-not (Get-Process -Id $gui.Id -ErrorAction SilentlyContinue)) { Write-Host "GUI exited early"; break }
    if ([W32V]::FindMain($gui.Id) -ne [IntPtr]::Zero) { break }
    Start-Sleep -Milliseconds 300
}
Write-Host "waiting for connect + hook injection (15s)..."
Start-Sleep -Seconds 15

# seed the ring (fakewar3 pid) with synthetic 0x017xxxxx events
& $lc "seed" $fake.Id
Start-Sleep -Seconds 3

# a) 伤害事件 page
$win = [System.Windows.Automation.AutomationElement]::FromHandle([W32V]::FindMain($gui.Id))
$cond = New-Object System.Windows.Automation.AndCondition(
    (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)),
    (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $TAB_HOOK)))
$tab = $win.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
if ($tab) { $tab.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select(); Write-Host "TAB hook selected" } else { Write-Host "WARN hook tab not found" }
Start-Sleep -Seconds 2
Shot-Pid $gui.Id (Join-Path $outdir "a_hook_page.png")

# b) 死亡结算 page -> double-click first row -> popup
$cond2 = New-Object System.Windows.Automation.AndCondition(
    (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)),
    (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $TAB_SETTLE)))
$tab2 = $win.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond2)
if ($tab2) { $tab2.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select(); Write-Host "TAB settle selected" } else { Write-Host "WARN settle tab not found" }
Start-Sleep -Seconds 2

# find the TOPMOST data grid (settle grid), not the bottom 伤害构成 grid
$cond3 = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::DataGrid)
$grids = $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond3)
$grid = $null; $minTop = 1e9
for ($i = 0; $i -lt $grids.Count; $i++) {
    $r = $grids.Item($i).Current.BoundingRectangle
    Write-Host ("GRID {0}: L={1} T={2} R={3} B={4}" -f $i, [int]$r.Left, [int]$r.Top, [int]$r.Right, [int]$r.Bottom)
    if ($r.Width -le 100 -or $r.Height -le 50) { continue }
    if ($r.Top -lt $minTop) { $minTop = $r.Top; $grid = $grids.Item($i) }
}
if ($grid) {
    $r = $grid.Current.BoundingRectangle
    Write-Host "CLICK GRID L=$($r.Left) T=$($r.Top) W=$($r.Width)"
    $main = [W32V]::FindMain($gui.Id)
    # 把主窗置顶再前台，避免合成点击落在控制台窗口上
    [W32V]::SetWindowPos($main, [IntPtr](-1), 0, 0, 0, 0, 0x0001 -bor 0x0002 -bor 0x0040) | Out-Null
    Start-Sleep -Milliseconds 400
    [W32V]::SetForegroundWindow($main) | Out-Null
    Start-Sleep -Milliseconds 300
    [W32V]::DblClick([int]($r.Left + 60), [int]($r.Top + 26 + 11))
    Start-Sleep -Seconds 2
    [W32V]::SetWindowPos($main, [IntPtr](-2), 0, 0, 0, 0, 0x0001 -bor 0x0002 -bor 0x0040) | Out-Null
} else { Write-Host "WARN no settle grid found" }

# diagnostics: enumerate all GUI windows via UIA
$rootEl = [System.Windows.Automation.AutomationElement]::RootElement
$pcond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, $gui.Id)
$wins = $rootEl.FindAll([System.Windows.Automation.TreeScope]::Children, $pcond)
for ($i = 0; $i -lt $wins.Count; $i++) { Write-Host ("WINDOW name='{0}' class='{1}'" -f $wins.Item($i).Current.Name, $wins.Item($i).Current.ClassName) }
$pop = [W32V]::FindByTitle($gui.Id, "0x")
if ($pop -ne [IntPtr]::Zero) { Write-Host "POPUP title: $([W32V]::Title($pop))"; Shot-Window $pop (Join-Path $outdir "b_popup.png") }
else { Write-Host "POPUP not found, fallback main window"; Shot-Pid $gui.Id (Join-Path $outdir "b_popup.png") }

Stop-Process -Id $gui.Id -Force -ErrorAction SilentlyContinue
Stop-Process -Id $fake.Id -Force -ErrorAction SilentlyContinue
Remove-Item Env:FAKE_UNITS,Env:FAKE_HEAP_MB,Env:FAKE_IMMORTAL,Env:FAKE_AMP -ErrorAction SilentlyContinue
Write-Host "VERIFY_HOOK DONE"
