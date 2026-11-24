# verify_popup_search.ps1 -- focused check: double-click a settlement row opens UnitEventsForm,
# then header search on 伤害来源 works and no 掩码 column. ASCII-only messages; Chinese names via code points.
$ErrorActionPreference = 'Stop'
$test = $PSScriptRoot
$root = Split-Path -Parent $test
$fg   = Join-Path $test "fakegame"
$bin  = Join-Path $root "bin\Release\net10.0-windows"
$outdir = Join-Path $test "verify_two_tabs"
New-Item -ItemType Directory -Force -Path $outdir | Out-Null

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W32P {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdc, uint flags);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmd);
  [DllImport("user32.dll")] public static extern bool UpdateWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint data, IntPtr extra);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr hWnd, System.Text.StringBuilder sb, int max);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint flags);
  public delegate bool EnumProc(IntPtr hWnd, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
  public static IntPtr FindMain(int pid) {
    IntPtr best = IntPtr.Zero; long area = 0;
    EnumWindows(delegate(IntPtr h, IntPtr l) {
      uint p; GetWindowThreadProcessId(h, out p);
      if (p != pid || !IsWindowVisible(h)) return true;
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
      if (p != pid || !IsWindowVisible(h)) return true;
      if (Title(h).Contains(sub)) { found = h; return false; } return true;
    }, IntPtr.Zero);
    return found;
  }
  public static void ListWindows(int pid) {
    EnumWindows(delegate(IntPtr h, IntPtr l) {
      uint p; GetWindowThreadProcessId(h, out p);
      if (p != pid) return true;
      RECT r; GetWindowRect(h, out r);
      Console.WriteLine("WIN vis=" + IsWindowVisible(h) + " title='" + Title(h) + "' rect=" + r.Left + "," + r.Top + "," + r.Right + "," + r.Bottom);
      return true;
    }, IntPtr.Zero);
  }
  public static void Click(int x, int y) {
    SetCursorPos(x, y); System.Threading.Thread.Sleep(100);
    mouse_event(0x02,0,0,0,IntPtr.Zero); mouse_event(0x04,0,0,0,IntPtr.Zero);
  }
  public static void DblClick(int x, int y) {
    SetCursorPos(x, y); System.Threading.Thread.Sleep(100);
    mouse_event(0x02,0,0,0,IntPtr.Zero); mouse_event(0x04,0,0,0,IntPtr.Zero);
    System.Threading.Thread.Sleep(120);
    mouse_event(0x02,0,0,0,IntPtr.Zero); mouse_event(0x04,0,0,0,IntPtr.Zero);
  }
  public static void WheelUp(int x, int y, int notches) {
    SetCursorPos(x, y); System.Threading.Thread.Sleep(100);
    for (int i = 0; i < notches; i++) { mouse_event(0x0800,0,0,120,IntPtr.Zero); System.Threading.Thread.Sleep(30); }
  }
}
"@

$TAB_SETTLE = -join (0x6B7B,0x4EA1,0x7ED3,0x7B97 | ForEach-Object { [char]$_ })
$TAB_HOOK   = -join (0x4F24,0x5BB3,0x4E8B,0x4EF6 | ForEach-Object { [char]$_ })
$HDR_SRC    = -join (0x4F24,0x5BB3,0x6765,0x6E90 | ForEach-Object { [char]$_ })
$HDR_MASK   = -join (0x63A9,0x7801 | ForEach-Object { [char]$_ })

function Fail([string]$msg) { Write-Host "FAIL: $msg"; throw $msg }
function Shot-Window([IntPtr]$hwnd, [string]$Out) {
    [W32P]::ShowWindow($hwnd, 9) | Out-Null; [W32P]::ShowWindow($hwnd, 5) | Out-Null
    [W32P]::SetForegroundWindow($hwnd) | Out-Null; [W32P]::UpdateWindow($hwnd) | Out-Null
    Start-Sleep -Milliseconds 700
    $r = New-Object W32P+RECT; [W32P]::GetWindowRect($hwnd, [ref]$r) | Out-Null
    $w = $r.Right - $r.Left; $h = $r.Bottom - $r.Top
    if ($w -le 0 -or $h -le 0) { $w = 1280; $h = 800 }
    $bmp = New-Object System.Drawing.Bitmap($w, $h); $g = [System.Drawing.Graphics]::FromImage($bmp)
    $hdc = $g.GetHdc(); [W32P]::PrintWindow($hwnd, $hdc, 2) | Out-Null; $g.ReleaseHdc($hdc); $g.Dispose()
    $bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
    Write-Host "SHOT $Out"
}
function Get-WinElement([IntPtr]$hwnd) { return [System.Windows.Automation.AutomationElement]::FromHandle($hwnd) }
function Select-Tab($win, [string]$name) {
    $cond = New-Object System.Windows.Automation.AndCondition(
        (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)),
        (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $name)))
    $tab = $win.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
    if ($null -eq $tab) { Fail "tab not found" }
    $tab.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
    Start-Sleep -Milliseconds 800
}
function Find-TopGrid($win) {
    $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::DataGrid)
    $grids = $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
    $best = $null; $bestTop = 1e9
    for ($i = 0; $i -lt $grids.Count; $i++) {
        $e = $grids.Item($i); $r = $e.Current.BoundingRectangle
        if ($r.Width -le 100 -or $r.Height -le 50) { continue }
        if ($e.Current.IsOffscreen) { continue }
        if ($r.Top -lt $bestTop) { $best = $e; $bestTop = $r.Top }
    }
    return $best
}
function Get-Headers($grid) {
    $names = @()
    try {
        $tp = $grid.GetCurrentPattern([System.Windows.Automation.TablePattern]::Pattern)
        foreach ($h in $tp.Current.GetColumnHeaders()) { $names += $h.Current.Name }
    } catch {
        $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::HeaderItem)
        $hs = $grid.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
        for ($i = 0; $i -lt $hs.Count; $i++) { $names += $hs.Item($i).Current.Name }
    }
    return ,$names
}
function Find-Header($grid, [string]$prefix) {
    try {
        $tp = $grid.GetCurrentPattern([System.Windows.Automation.TablePattern]::Pattern)
        foreach ($h in $tp.Current.GetColumnHeaders()) { if ($h.Current.Name.StartsWith($prefix)) { return $h } }
    } catch { }
    $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::HeaderItem)
    $hs = $grid.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
    for ($i = 0; $i -lt $hs.Count; $i++) { if ($hs.Item($i).Current.Name.StartsWith($prefix)) { return $hs.Item($i) } }
    return $null
}
function Click-Element($elem) {
    $r = $elem.Current.BoundingRectangle
    [W32P]::SetCursorPos([int]($r.Left + $r.Width / 2), [int]($r.Top + $r.Height / 2)) | Out-Null
    Start-Sleep -Milliseconds 100
    [W32P]::mouse_event(0x02,0,0,0,[IntPtr]::Zero); [W32P]::mouse_event(0x04,0,0,0,[IntPtr]::Zero)
}

$env:FAKE_UNITS='30'; $env:FAKE_HEAP_MB='0'; $env:FAKE_IMMORTAL='0'; $env:FAKE_AMP='150'
$fo = Join-Path $fg "vps_fake_out.log"; $fe = Join-Path $fg "vps_fake_err.log"
Remove-Item $fo,$fe -ErrorAction SilentlyContinue
$fake = Start-Process -FilePath (Join-Path $fg "fakewar3.exe") -ArgumentList "180" -WorkingDirectory $fg `
    -RedirectStandardOutput $fo -RedirectStandardError $fe -PassThru -WindowStyle Hidden
Write-Host "FAKE PID=$($fake.Id)"
Start-Sleep -Seconds 2

$go = Join-Path $bin "vps_gui_out.log"; $ge = Join-Path $bin "vps_gui_err.log"
Remove-Item $go,$ge -ErrorAction SilentlyContinue
$gui = Start-Process -FilePath (Join-Path $bin "War3DeathSettlement.exe") `
    -ArgumentList "--name","fakewar3","--force-version","1.27.0.52240" -WorkingDirectory $bin `
    -RedirectStandardOutput $go -RedirectStandardError $ge -PassThru -WindowStyle Normal
Write-Host "GUI PID=$($gui.Id)"

$deadline = (Get-Date).AddSeconds(30)
$hwnd = [IntPtr]::Zero
while ((Get-Date) -lt $deadline) {
    if (-not (Get-Process -Id $gui.Id -ErrorAction SilentlyContinue)) { Fail "GUI exited early" }
    $hwnd = [W32P]::FindMain($gui.Id)
    if ($hwnd -ne [IntPtr]::Zero) { break }
    Start-Sleep -Milliseconds 300
}
if ($hwnd -eq [IntPtr]::Zero) { Fail "GUI window did not appear" }
Write-Host "waiting 10s for hook/settlements..."
Start-Sleep -Seconds 10

$win = Get-WinElement $hwnd
Select-Tab $win $TAB_SETTLE
Start-Sleep -Seconds 1
$win = Get-WinElement $hwnd
$grid = Find-TopGrid $win
if ($null -eq $grid) { Fail "settle grid not found" }
$r = $grid.Current.BoundingRectangle
Write-Host ("GRID rect= {0},{1} {2}x{3}" -f $r.Left,$r.Top,$r.Width,$r.Height)
$gp = $grid.GetCurrentPattern([System.Windows.Automation.GridPattern]::Pattern)
Write-Host ("GRID rows={0} cols={1}" -f $gp.Current.RowCount, $gp.Current.ColumnCount)
# live rows are appended after settlements; the view may be anchored at the bottom -> wheel to top
[W32P]::WheelUp([int]($r.Left + $r.Width / 2), [int]($r.Top + $r.Height / 2), 40)
Start-Sleep -Milliseconds 600
Write-Host "wheeled settle grid to top"
$clickX = [int]($r.Left + 60)
$clickY = [int]($r.Top + 26 + 11)
Write-Host "click cell row0 at $clickX,$clickY"
Shot-Window $hwnd (Join-Path $outdir "10_before_dblclick.png")
[W32P]::SetWindowPos($hwnd, [IntPtr](-1), 0,0,0,0, 0x0001 -bor 0x0002 -bor 0x0040) | Out-Null
[W32P]::SetForegroundWindow($hwnd) | Out-Null
Start-Sleep -Milliseconds 600
# first click focuses the grid; then a clean double-click on the same cell
[W32P]::SetCursorPos($clickX, $clickY) | Out-Null
Start-Sleep -Milliseconds 100
[W32P]::mouse_event(0x02,0,0,0,[IntPtr]::Zero); [W32P]::mouse_event(0x04,0,0,0,[IntPtr]::Zero)
Start-Sleep -Milliseconds 300
[W32P]::DblClick($clickX, $clickY)
Start-Sleep -Seconds 2
Write-Host "windows after dblclick:"
[W32P]::ListWindows($gui.Id)
Shot-Window $hwnd (Join-Path $outdir "11_after_dblclick_main.png")

$rootEl = [System.Windows.Automation.AutomationElement]::RootElement
$pcond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, $gui.Id)
$wins = $rootEl.FindAll([System.Windows.Automation.TreeScope]::Children, $pcond)
Write-Host "UIA windows:"
for ($i = 0; $i -lt $wins.Count; $i++) {
    Write-Host ("  name='{0}' class='{1}' offscreen={2}" -f $wins.Item($i).Current.Name, $wins.Item($i).Current.ClassName, $wins.Item($i).Current.IsOffscreen)
}

# find popup by title containing '0x'
$popHwnd = [W32P]::FindByTitle($gui.Id, "0x")
if ($popHwnd -eq [IntPtr]::Zero) {
    for ($i = 0; $i -lt $wins.Count; $i++) {
        $w = $wins.Item($i)
        if ($w.Current.Name -like "*0x*" -and $w.Current.Name -ne "") {
            $popHwnd = [IntPtr][long]$w.Current.NativeWindowHandle
            break
        }
    }
}
if ($popHwnd -eq [IntPtr]::Zero) { Fail "popup window not found" }
Write-Host ("POPUP title={0}" -f [W32P]::Title($popHwnd))
$popWin = Get-WinElement $popHwnd
$popGrid = Find-TopGrid $popWin
if ($null -eq $popGrid) { Fail "popup grid not found" }
$headers = Get-Headers $popGrid
Write-Host ("POPUP HEADERS = {0}" -f ($headers -join ' | '))
if ($headers -contains $HDR_MASK) { Fail "popup still has mask column" }
Shot-Window $popHwnd (Join-Path $outdir "12_popup_no_mask.png")
# let the just-shown form finish layout/centering before using header bounds
Start-Sleep -Seconds 2
# the form may recentre/resize during its first paint -> re-resolve HWND/element/grid
$popHwnd = [W32P]::FindByTitle($gui.Id, "0x")
if ($popHwnd -eq [IntPtr]::Zero) { Fail "popup window lost" }
$popWin = Get-WinElement $popHwnd
$popGrid = Find-TopGrid $popWin
if ($null -eq $popGrid) { Fail "popup grid lost after layout" }
$headers2 = Get-Headers $popGrid
if ($headers2 -contains $HDR_MASK) { Fail "popup has mask column after layout" }

# 'e' matches the fake codes that actually show up as 伤害来源 (uske/opeo/ogre/ewsp),
# so the filtered table is non-empty and both rows + header can be verified.
$keyword = "e"
Write-Host "POPUP keyword=$keyword"

# main window was made topmost for the dblclick; remove that so the popup can come to front
[W32P]::SetWindowPos($hwnd, [IntPtr](-2), 0,0,0,0, 0x0001 -bor 0x0002 -bor 0x0040) | Out-Null
[W32P]::SetWindowPos($popHwnd, [IntPtr](-1), 0,0,0,0, 0x0001 -bor 0x0002 -bor 0x0040) | Out-Null
[W32P]::SetForegroundWindow($popHwnd) | Out-Null
Start-Sleep -Milliseconds 600
$editCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Edit)
$edits = 0
for ($attempt = 0; $attempt -lt 3; $attempt++) {
    $srcHeader = Find-Header $popGrid $HDR_SRC
    if ($null -eq $srcHeader) { Fail "popup source header not found" }
    $hr = $srcHeader.Current.BoundingRectangle
    Write-Host ("POPUP source header rect={0},{1} {2}x{3}" -f $hr.Left,$hr.Top,$hr.Width,$hr.Height)
    Click-Element $srcHeader
    Start-Sleep -Milliseconds 700
    $edits = $popWin.FindAll([System.Windows.Automation.TreeScope]::Descendants, $editCond).Count
    Write-Host ("POPUP search editor attempt {0}: edits={1}" -f ($attempt + 1), $edits)
    if ($edits -gt 0) { break }
    [W32P]::SetForegroundWindow($popHwnd) | Out-Null
}
if ($edits -le 0) { Fail "popup search editor did not open" }
$edit = $popWin.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $editCond)
try { $edit.SetFocus() } catch { Write-Host ("edit SetFocus failed: {0}" -f $_.Exception.Message) }
Start-Sleep -Milliseconds 300
[System.Windows.Forms.SendKeys]::SendWait($keyword)
Start-Sleep -Milliseconds 1200
try {
    $vp = $edit.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)
    Write-Host ("POPUP search box value='{0}'" -f $vp.Current.Value)
} catch { Write-Host "POPUP search box value unreadable" }
Shot-Window $popHwnd (Join-Path $outdir "12b_popup_after_type.png")
# Tab moves focus out of the editor -> the component's Leave path applies + closes the search box.
try { $edit.SetFocus() } catch { }
Start-Sleep -Milliseconds 200
[System.Windows.Forms.SendKeys]::SendWait("{TAB}")
Start-Sleep -Milliseconds 1000
$editsAfter = $popWin.FindAll([System.Windows.Automation.TreeScope]::Descendants, $editCond).Count
Write-Host "POPUP edits after Tab=$editsAfter"
Shot-Window $popHwnd (Join-Path $outdir "12c_popup_after_leave.png")
$popWin = Get-WinElement $popHwnd
$popGrid = Find-TopGrid $popWin
if ($null -eq $popGrid) { Fail "popup grid not found after filter" }
$headers = Get-Headers $popGrid
Write-Host ("POPUP HEADERS filtered = {0}" -f ($headers -join ' | '))
$expect = "$HDR_SRC（⌕ $keyword）"
if ($headers -notcontains $expect) { Fail "popup header filter indicator missing (expected '$expect')" }
$gp2 = $popGrid.GetCurrentPattern([System.Windows.Automation.GridPattern]::Pattern)
$popRows = $gp2.Current.RowCount
Write-Host ("POPUP rows filtered = {0}" -f $popRows)
if ($popRows -lt 1) { Fail "popup filter produced 0 rows (expected at least one)" }
$bad = 0; $checked = 0
for ($i = 0; $i -lt $popRows; $i++) {
    $t = $gp2.GetItem($i, 4).Current.Name
    if ([string]::IsNullOrEmpty($t)) { continue }
    $checked++
    if (-not $t.ToLowerInvariant().Contains($keyword)) { $bad++ }
}
Write-Host ("POPUP FILTER checked={0} bad={1}" -f $checked,$bad)
if ($checked -gt 0 -and $bad -ne 0) { Fail "popup source filter mismatch" }
if ($checked -eq 0) { Write-Host "WARN: popup cell text not exposed by UIA; header + row count verified" }
Shot-Window $popHwnd (Join-Path $outdir "13_popup_filtered.png")

# click 刷新 to move focus out of the still-open search box, then take a clean screenshot
$refreshText = -join (0x5237,0x65B0 | ForEach-Object { [char]$_ })
$btnCond = New-Object System.Windows.Automation.AndCondition(
    (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)),
    (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $refreshText)))
$refresh = $popWin.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $btnCond)
if ($null -ne $refresh) {
    Click-Element $refresh
    Start-Sleep -Milliseconds 1200
    $popWin = Get-WinElement $popHwnd
    $popGrid = Find-TopGrid $popWin
    if ($null -ne $popGrid) {
        $headers3 = Get-Headers $popGrid
        Write-Host ("POPUP HEADERS after blur = {0}" -f ($headers3 -join ' | '))
        if ($headers3 -notcontains $expect) { Fail "popup filter lost after blur" }
        Shot-Window $popHwnd (Join-Path $outdir "14_popup_filtered_clean.png")
    }
}

[W32P]::SetForegroundWindow($popHwnd) | Out-Null
[System.Windows.Forms.SendKeys]::SendWait("%{F4}")
Start-Sleep -Milliseconds 800
$gui.CloseMainWindow() | Out-Null
Start-Sleep -Seconds 2
if (-not $gui.HasExited) { Stop-Process -Id $gui.Id -Force -ErrorAction SilentlyContinue }
Stop-Process -Id $fake.Id -Force -ErrorAction SilentlyContinue
Remove-Item Env:FAKE_UNITS,Env:FAKE_HEAP_MB,Env:FAKE_IMMORTAL,Env:FAKE_AMP -ErrorAction SilentlyContinue
Write-Host "VERIFY_POPUP DONE"
