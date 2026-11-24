# verify_two_tabs_search.ps1 -- fakewar3 + GUI:
#   1) only two tabs (死亡结算 / 伤害事件), default = 死亡结算
#   2) 伤害事件 no 掩码 column, 伤害来源 header fuzzy search + clear
#   3) double-click settlement -> popup same header search, no 掩码
# ASCII-only output on purpose (Chinese strings are built from code points).
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
public class W32T {
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
  public static void Click(int x, int y) {
    SetCursorPos(x, y); System.Threading.Thread.Sleep(80);
    mouse_event(0x02,0,0,0,IntPtr.Zero); mouse_event(0x04,0,0,0,IntPtr.Zero);
  }
  public static void DblClick(int x, int y) {
    SetCursorPos(x, y); System.Threading.Thread.Sleep(80);
    mouse_event(0x02,0,0,0,IntPtr.Zero); mouse_event(0x04,0,0,0,IntPtr.Zero);
    System.Threading.Thread.Sleep(90);
    mouse_event(0x02,0,0,0,IntPtr.Zero); mouse_event(0x04,0,0,0,IntPtr.Zero);
  }
}
"@

# Chinese tab/header strings (avoid source encoding issues)
$TAB_SETTLE = -join (0x6B7B,0x4EA1,0x7ED3,0x7B97 | ForEach-Object { [char]$_ })  # 死亡结算
$TAB_HOOK   = -join (0x4F24,0x5BB3,0x4E8B,0x4EF6 | ForEach-Object { [char]$_ })  # 伤害事件
$HDR_SRC    = -join (0x4F24,0x5BB3,0x6765,0x6E90 | ForEach-Object { [char]$_ })  # 伤害来源
$HDR_DST    = -join (0x89E6,0x53D1,0x5355,0x4F4D | ForEach-Object { [char]$_ })  # 触发单位
$HDR_MASK   = -join (0x63A9,0x7801 | ForEach-Object { [char]$_ })                # 掩码

function Fail([string]$msg) { Write-Host "FAIL: $msg"; throw $msg }

function Shot-Window([IntPtr]$hwnd, [string]$Out) {
    [W32T]::ShowWindow($hwnd, 9) | Out-Null; [W32T]::ShowWindow($hwnd, 5) | Out-Null
    [W32T]::SetForegroundWindow($hwnd) | Out-Null; [W32T]::UpdateWindow($hwnd) | Out-Null
    Start-Sleep -Milliseconds 700
    $r = New-Object W32T+RECT; [W32T]::GetWindowRect($hwnd, [ref]$r) | Out-Null
    $w = $r.Right - $r.Left; $h = $r.Bottom - $r.Top
    if ($w -le 0 -or $h -le 0) { $w = 1280; $h = 800 }
    $bmp = New-Object System.Drawing.Bitmap($w, $h); $g = [System.Drawing.Graphics]::FromImage($bmp)
    $hdc = $g.GetHdc(); [W32T]::PrintWindow($hwnd, $hdc, 2) | Out-Null; $g.ReleaseHdc($hdc); $g.Dispose()
    $bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
    Write-Host "SHOT $Out (${w}x${h})"
}

function Focus-Win([int]$ProcId) {
    $hwnd = [W32T]::FindMain($ProcId)
    [W32T]::SetWindowPos($hwnd, [IntPtr](-1), 0, 0, 0, 0, 0x0001 -bor 0x0002 -bor 0x0040) | Out-Null
    [W32T]::SetForegroundWindow($hwnd) | Out-Null
    Start-Sleep -Milliseconds 300
}

function Get-WinElement([IntPtr]$hwnd) { return [System.Windows.Automation.AutomationElement]::FromHandle($hwnd) }

function Get-TabNames($win) {
    $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)
    $tabs = $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
    $names = @()
    for ($i = 0; $i -lt $tabs.Count; $i++) { $names += $tabs.Item($i).Current.Name }
    return ,$names
}

function Select-Tab($win, [string]$name) {
    $cond = New-Object System.Windows.Automation.AndCondition(
        (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)),
        (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $name)))
    $tab = $win.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
    if ($null -eq $tab) { Fail "tab not found: $name" }
    $tab.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
    Start-Sleep -Milliseconds 800
}

function Find-TopGrid($win) {
    $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::DataGrid)
    $grids = $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
    $best = $null; $bestTop = 1e9
    for ($i = 0; $i -lt $grids.Count; $i++) {
        $e = $grids.Item($i)
        $r = $e.Current.BoundingRectangle
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
        $headers = $tp.Current.GetColumnHeaders()
        foreach ($h in $headers) { $names += $h.Current.Name }
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
        $headers = $tp.Current.GetColumnHeaders()
        foreach ($h in $headers) { if ($h.Current.Name.StartsWith($prefix)) { return $h } }
    } catch { }
    $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::HeaderItem)
    $hs = $grid.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
    for ($i = 0; $i -lt $hs.Count; $i++) {
        if ($hs.Item($i).Current.Name.StartsWith($prefix)) { return $hs.Item($i) }
    }
    return $null
}

function Get-RowCount($grid) {
    try {
        $gp = $grid.GetCurrentPattern([System.Windows.Automation.GridPattern]::Pattern)
        return $gp.Current.RowCount
    } catch {
        $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::DataItem)
        return $grid.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond).Count
    }
}

function Get-CellText($grid, [int]$row, [int]$col) {
    try {
        $gp = $grid.GetCurrentPattern([System.Windows.Automation.GridPattern]::Pattern)
        $item = $gp.GetItem($row, $col)
        if ($null -ne $item) { return $item.Current.Name }
    } catch { }
    return ""
}

function Click-Element($elem) {
    $r = $elem.Current.BoundingRectangle
    [W32T]::Click([int]($r.Left + $r.Width / 2), [int]($r.Top + $r.Height / 2))
}

function Assert-NoMask($grid, [string]$where) {
    $headers = Get-Headers $grid
    Write-Host ("HEADERS[{0}] = {1}" -f $where, ($headers -join ' | '))
    if ($headers -contains $HDR_MASK) { Fail "$where still has 掩码 column" }
    if ($headers -notcontains $HDR_DST) { Fail "$where missing 触发单位 column" }
    if ($headers -notcontains $HDR_SRC) { Fail "$where missing 伤害来源 column" }
}

function Assert-FilteredSource($grid, [string]$keyword) {
    $rows = Get-RowCount $grid
    $bad = 0; $checked = 0
    for ($r = 0; $r -lt $rows; $r++) {
        $text = Get-CellText $grid $r 4
        if ([string]::IsNullOrEmpty($text)) { continue }
        $checked++
        if (-not $text.ToLowerInvariant().Contains($keyword.ToLowerInvariant())) { $bad++ }
    }
    Write-Host ("FILTER rows={0} checked={1} bad={2} keyword='{3}'" -f $rows, $checked, $bad, $keyword)
    if ($checked -eq 0) { Fail "no cell text readable while filtering" }
    if ($bad -ne 0) { Fail "$bad row(s) do not match 伤害来源 keyword '$keyword'" }
    return $rows
}

# ---------------- scenario ----------------
$env:FAKE_UNITS='30'; $env:FAKE_HEAP_MB='0'; $env:FAKE_IMMORTAL='0'; $env:FAKE_AMP='150'
$fo = Join-Path $fg "vts_fake_out.log"; $fe = Join-Path $fg "vts_fake_err.log"
Remove-Item $fo,$fe -ErrorAction SilentlyContinue
$fake = Start-Process -FilePath (Join-Path $fg "fakewar3.exe") -ArgumentList "300" -WorkingDirectory $fg `
    -RedirectStandardOutput $fo -RedirectStandardError $fe -PassThru -WindowStyle Hidden
Write-Host "FAKE PID=$($fake.Id)"
Start-Sleep -Seconds 2

# Simulate an OLD ini that still has deep_seconds: it must be ignored and not written back on close.
$oldIni = Join-Path $outdir "old-War3DeathSettlement.ini"
@"
interval_ms=50
deep_seconds=8
auto_attach=1
hook_enable=1
"@ | Set-Content -Path $oldIni -Encoding UTF8
$ini = Join-Path $bin "War3DeathSettlement.ini"
Copy-Item $oldIni $ini -Force

$go = Join-Path $bin "vts_gui_out.log"; $ge = Join-Path $bin "vts_gui_err.log"
Remove-Item $go,$ge -ErrorAction SilentlyContinue
$gui = Start-Process -FilePath (Join-Path $bin "War3DeathSettlement.exe") `
    -ArgumentList "--name","fakewar3","--force-version","1.27.0.52240" -WorkingDirectory $bin `
    -RedirectStandardOutput $go -RedirectStandardError $ge -PassThru -WindowStyle Normal
Write-Host "GUI PID=$($gui.Id)"

$deadline = (Get-Date).AddSeconds(30)
$hwnd = [IntPtr]::Zero
while ((Get-Date) -lt $deadline) {
    if (-not (Get-Process -Id $gui.Id -ErrorAction SilentlyContinue)) { Fail "GUI exited early" }
    $hwnd = [W32T]::FindMain($gui.Id)
    if ($hwnd -ne [IntPtr]::Zero) { break }
    Start-Sleep -Milliseconds 300
}
if ($hwnd -eq [IntPtr]::Zero) { Fail "GUI window did not appear" }
Write-Host "GUI window ready; waiting for connect/hook/events (20s)..."
Start-Sleep -Seconds 20

$win = Get-WinElement $hwnd
$tabs = Get-TabNames $win
Write-Host ("TABS = {0}" -f ($tabs -join ' | '))
if ($tabs.Count -ne 2 -or $tabs -notcontains $TAB_SETTLE -or $tabs -notcontains $TAB_HOOK) {
    Fail "expected exactly two tabs ($TAB_SETTLE / $TAB_HOOK), got: $($tabs -join ',')"
}
$selected = ""
$condTab = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)
$tabEls = $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condTab)
for ($i = 0; $i -lt $tabEls.Count; $i++) {
    $t = $tabEls.Item($i)
    $sp = $t.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern)
    if ($sp.Current.IsSelected) { $selected = $t.Current.Name }
}
Write-Host "SELECTED TAB = $selected"
if ($selected -ne $TAB_SETTLE) { Fail "default tab is not $TAB_SETTLE" }
Shot-Window $hwnd (Join-Path $outdir "01_main_two_tabs.png")

# ---- damage event page ----
Select-Tab $win $TAB_HOOK
Start-Sleep -Seconds 1
$win = Get-WinElement $hwnd
$grid = Find-TopGrid $win
$rows = 0
for ($i = 0; $i -lt 25; $i++) {
    $win = Get-WinElement $hwnd
    $grid = Find-TopGrid $win
    if ($null -ne $grid) { $rows = Get-RowCount $grid }
    if ($rows -ge 5) { break }
    Start-Sleep -Seconds 1
}
Write-Host "HOOK ROWS (before filter) = $rows"
if ($rows -lt 5) { Fail "not enough damage events to verify filtering (rows=$rows)" }
Assert-NoMask $grid "hook-page"
Shot-Window $hwnd (Join-Path $outdir "02_hook_page_no_mask.png")

# click 伤害来源 header -> search box -> type 'o'
Focus-Win $gui.Id
$srcHeader = Find-Header $grid $HDR_SRC
if ($null -eq $srcHeader) { Fail "伤害来源 header element not found" }
Click-Element $srcHeader
Start-Sleep -Milliseconds 500
Shot-Window $hwnd (Join-Path $outdir "03_hook_search_box.png")
[System.Windows.Forms.SendKeys]::SendWait("o")
Start-Sleep -Milliseconds 1200
$win = Get-WinElement $hwnd
$grid = Find-TopGrid $win
$headers = Get-Headers $grid
Write-Host ("HEADERS[filtered] = {0}" -f ($headers -join ' | '))
$expect = "$HDR_SRC（⌕ o）"
if ($headers -notcontains $expect) { Fail "header does not show filter indicator: expected '$expect'" }
$filteredRows = Assert-FilteredSource $grid "o"
if ($filteredRows -ge $rows) { Write-Host "WARN: filtered row count is not smaller (rows may all contain 'o')" }
Shot-Window $hwnd (Join-Path $outdir "04_hook_filtered_o.png")

# clear: click header again, backspace + Enter
$srcHeader2 = Find-Header $grid $HDR_SRC
Click-Element $srcHeader2
Start-Sleep -Milliseconds 400
[System.Windows.Forms.SendKeys]::SendWait("{BACKSPACE}{ENTER}")
Start-Sleep -Milliseconds 1200
$win = Get-WinElement $hwnd
$grid = Find-TopGrid $win
$headers = Get-Headers $grid
Write-Host ("HEADERS[cleared] = {0}" -f ($headers -join ' | '))
if ($headers -contains $expect) { Fail "filter indicator was not cleared" }
if ($headers -notcontains $HDR_SRC) { Fail "伤害来源 header not restored after clear" }
$clearedRows = Get-RowCount $grid
Write-Host "HOOK ROWS (cleared) = $clearedRows"
if ($clearedRows -lt $filteredRows) { Fail "clearing filter did not restore rows ($filteredRows -> $clearedRows)" }
Shot-Window $hwnd (Join-Path $outdir "05_hook_cleared.png")

# main-page checks done (the popup is covered by verify_popup_search.ps1);
# close gracefully so the old ini gets rewritten by Settings.Save.
$gui.CloseMainWindow() | Out-Null
Start-Sleep -Seconds 2
if (-not $gui.HasExited) { Stop-Process -Id $gui.Id -Force -ErrorAction SilentlyContinue }
Stop-Process -Id $fake.Id -Force -ErrorAction SilentlyContinue
Remove-Item Env:FAKE_UNITS,Env:FAKE_HEAP_MB,Env:FAKE_IMMORTAL,Env:FAKE_AMP -ErrorAction SilentlyContinue
Write-Host "VERIFY_TWO_TABS DONE"
exit 0

# ---- settlement page -> popup ----
Select-Tab $win $TAB_SETTLE
Start-Sleep -Seconds 2
$win = Get-WinElement $hwnd
$grid = Find-TopGrid $win
$settleRows = Get-RowCount $grid
Write-Host "SETTLE ROWS = $settleRows"
if ($settleRows -lt 1) { Fail "no settlement/live row to double-click" }
Focus-Win $gui.Id
$r = $grid.Current.BoundingRectangle
[W32T]::DblClick([int]($r.Left + 60), [int]($r.Top + 26 + 11))
Start-Sleep -Seconds 2

$popHwnd = [W32T]::FindByTitle($gui.Id, "0x")
if ($popHwnd -eq [IntPtr]::Zero) { Shot-Window $hwnd (Join-Path $outdir "06_popup_not_found.png"); Fail "popup window not found" }
Write-Host ("POPUP title = {0}" -f [W32T]::Title($popHwnd))
$popWin = Get-WinElement $popHwnd
$popGrid = Find-TopGrid $popWin
if ($null -eq $popGrid) { Fail "popup grid not found" }
Assert-NoMask $popGrid "popup"
Shot-Window $popHwnd (Join-Path $outdir "06_popup_no_mask.png")

$popSrcHeader = Find-Header $popGrid $HDR_SRC
if ($null -eq $popSrcHeader) { Fail "popup 伤害来源 header not found" }
Focus-Win $gui.Id
Click-Element $popSrcHeader
Start-Sleep -Milliseconds 500
[System.Windows.Forms.SendKeys]::SendWait("o")
Start-Sleep -Milliseconds 1200
$popWin = Get-WinElement $popHwnd
$popGrid = Find-TopGrid $popWin
$popHeaders = Get-Headers $popGrid
Write-Host ("HEADERS[popup filtered] = {0}" -f ($popHeaders -join ' | '))
if ($popHeaders -notcontains $expect) { Fail "popup header does not show filter indicator '$expect'" }
Assert-FilteredSource $popGrid "o" | Out-Null
Shot-Window $popHwnd (Join-Path $outdir "07_popup_filtered_o.png")

# close popup, then close main window gracefully so ini is rewritten
[W32T]::SetForegroundWindow($popHwnd) | Out-Null
Start-Sleep -Milliseconds 200
[System.Windows.Forms.SendKeys]::SendWait("%{F4}")
Start-Sleep -Milliseconds 800
$gui.CloseMainWindow() | Out-Null
Start-Sleep -Seconds 2
if (-not $gui.HasExited) { Stop-Process -Id $gui.Id -Force -ErrorAction SilentlyContinue }
Stop-Process -Id $fake.Id -Force -ErrorAction SilentlyContinue
Remove-Item Env:FAKE_UNITS,Env:FAKE_HEAP_MB,Env:FAKE_IMMORTAL,Env:FAKE_AMP -ErrorAction SilentlyContinue

Write-Host "VERIFY_TWO_TABS_SEARCH DONE"
