param(
    [ValidateSet('jass', 'nojass')]
    [string]$Scenario = 'jass'
)
# verify_units_page.ps1 -- fakewar3 + GUI: battlefield-units page end-to-end.
#   -Scenario jass   : the fake game.dll installs a minimal JASS native table, so attribute columns
#                      have numbers and hero rows show two lines (title + name); header search for
#                      type code and for the unit-name column (matching the hero TITLE) is verified.
#   -Scenario nojass : FAKE_NO_JASS=1 -> no JASS at all -> every attribute cell must be "?".
# ASCII ONLY on purpose (Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI); Chinese strings are
# built from code points at runtime.
$ErrorActionPreference = 'Stop'

$test = $PSScriptRoot
$root = Split-Path -Parent $test
$fg   = Join-Path $test "fakegame"
$bin  = Join-Path $root "bin\Release\net10.0-windows"
$outdir = Join-Path $test "units_page"
New-Item -ItemType Directory -Force -Path $outdir | Out-Null

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W32U {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdc, uint flags);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmd);
  [DllImport("user32.dll")] public static extern bool UpdateWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint data, IntPtr extra);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
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
  public static void Click(int x, int y) {
    SetCursorPos(x, y); System.Threading.Thread.Sleep(80);
    mouse_event(0x02,0,0,0,IntPtr.Zero); mouse_event(0x04,0,0,0,IntPtr.Zero);
  }
}
"@

function T([int[]]$cp) { -join ($cp | ForEach-Object { [char]$_ }) }

$TAB_UNITS = T @(0x6218,0x573A,0x5355,0x4F4D)                                  # zhan chang dan wei
$HDR_CODE  = T @(0x7C7B,0x578B,0x7801)                                        # lei xing ma
$HDR_NAME  = T @(0x5355,0x4F4D,0x540D,0x79F0,0xFF08,0x79F0,0x8C13,0xFF09)     # dan wei ming cheng + (cheng wei)
$HDR_OWNER = T @(0x62E5,0x6709,0x8005)                                        # yong you zhe
$HDR_ADDR  = T @(0x5730,0x5740)                                               # di zhi
$TITLE_UTH = T @(0x4E4C,0x745F,0x5C14)                                        # hero proper name (fake JASS)
$NAME_PAL  = T @(0x5723,0x9A91,0x58EB)                                        # unit name (fake JASS)
$KW_TITLE  = T @(0x4E4C,0x745F)                                               # title keyword (2 chars)
$LBRACKET  = T @(0xFF08,0x2315,0x20)                                          # full-width "(" + search glyph + space
$RBRACKET  = T @(0xFF09)                                                      # full-width ")"
$EXPECT_HEADERS = @(
  $HDR_CODE, $HDR_NAME,
  (T @(0x653B,0x51FB,0x8303,0x56F4)),                 # attack range
  (T @(0x653B,0x51FB,0x529B)),                        # attack damage
  (T @(0x653B,0x51FB,0x95F4,0x9694)),                 # attack interval
  (T @(0x62A4,0x7532)),                               # armor
  (T @(0x79FB,0x901F)),                               # move speed
  (T @(0x767D,0x5929,0x89C6,0x91CE)),                 # day sight
  (T @(0x591C,0x665A,0x89C6,0x91CE)),                 # night sight
  (T @(0x4E3B,0x52A8,0x653B,0x51FB,0x8303,0x56F4)),   # acquire range
  (T @(0x529B,0x91CF)),                               # strength
  (T @(0x654F,0x6377)),                               # agility
  (T @(0x667A,0x529B)),                               # intelligence
  $HDR_OWNER, $HDR_ADDR
)

function Fail([string]$msg) { Write-Host "FAIL: $msg"; throw $msg }
function Ok([string]$msg)  { Write-Host "PASS: $msg" }

function Shot-Window([IntPtr]$hwnd, [string]$Out) {
    [W32U]::ShowWindow($hwnd, 9) | Out-Null; [W32U]::ShowWindow($hwnd, 5) | Out-Null
    [W32U]::SetForegroundWindow($hwnd) | Out-Null; [W32U]::UpdateWindow($hwnd) | Out-Null
    Start-Sleep -Milliseconds 700
    $r = New-Object W32U+RECT; [W32U]::GetWindowRect($hwnd, [ref]$r) | Out-Null
    $w = $r.Right - $r.Left; $h = $r.Bottom - $r.Top
    if ($w -le 0 -or $h -le 0) { $w = 1280; $h = 800 }
    $bmp = New-Object System.Drawing.Bitmap($w, $h); $g = [System.Drawing.Graphics]::FromImage($bmp)
    $hdc = $g.GetHdc(); [W32U]::PrintWindow($hwnd, $hdc, 2) | Out-Null; $g.ReleaseHdc($hdc); $g.Dispose()
    $bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
    Write-Host "SHOT $Out (${w}x${h})"
}

function Get-WinElement([IntPtr]$hwnd) { return [System.Windows.Automation.AutomationElement]::FromHandle($hwnd) }

function Select-Tab($win, [string]$name) {
    $cond = New-Object System.Windows.Automation.AndCondition(
        (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)),
        (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $name)))
    $tab = $win.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
    if ($null -eq $tab) { Fail "tab not found: $name" }
    $tab.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
    Start-Sleep -Milliseconds 1200
}

function Get-TabNames($win) {
    $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)
    $tabs = $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
    $names = @()
    for ($i = 0; $i -lt $tabs.Count; $i++) { $names += $tabs.Item($i).Current.Name }
    return ,$names
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
    $tp = $grid.GetCurrentPattern([System.Windows.Automation.TablePattern]::Pattern)
    $headers = $tp.Current.GetColumnHeaders()
    for ($i = 0; $i -lt $headers.Count; $i++) { $names += $headers.Item($i).Current.Name }
    return ,$names
}

function Find-Header($grid, [string]$prefix) {
    $tp = $grid.GetCurrentPattern([System.Windows.Automation.TablePattern]::Pattern)
    $headers = $tp.Current.GetColumnHeaders()
    for ($i = 0; $i -lt $headers.Count; $i++) {
        if ($headers.Item($i).Current.Name.StartsWith($prefix)) { return $headers.Item($i) }
    }
    return $null
}

function Get-RowCount($grid) {
    $gp = $grid.GetCurrentPattern([System.Windows.Automation.GridPattern]::Pattern)
    return $gp.Current.RowCount
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
    [W32U]::Click([int]($r.Left + $r.Width / 2), [int]($r.Top + $r.Height / 2))
}

# Type into the header search box with clipboard + Ctrl+V (works for ASCII and Chinese alike;
# clicking a header already focused the TextBox, so SendKeys goes straight into it).
function Set-SearchText([string]$text) {
    if ($text.Length -gt 0) { Set-Clipboard -Value $text }
    [System.Windows.Forms.SendKeys]::SendWait("^a")
    Start-Sleep -Milliseconds 150
    if ($text.Length -gt 0) { [System.Windows.Forms.SendKeys]::SendWait("^v") }
    else { [System.Windows.Forms.SendKeys]::SendWait("{BACKSPACE}") }
    Start-Sleep -Milliseconds 1000
}

# ---------------- scenario ----------------
$env:FAKE_UNITS = '12'
$env:FAKE_IMMORTAL = '1'
$env:FAKE_AMP = '100'
Remove-Item Env:FAKE_NO_JASS -ErrorAction SilentlyContinue
if ($Scenario -eq 'nojass') { $env:FAKE_NO_JASS = '1' }
$fo = Join-Path $fg ("units_" + $Scenario + "_out.log")
$fe = Join-Path $fg ("units_" + $Scenario + "_err.log")
Remove-Item $fo,$fe -ErrorAction SilentlyContinue
$fake = Start-Process -FilePath (Join-Path $fg "fakewar3.exe") -ArgumentList "300" -WorkingDirectory $fg `
    -RedirectStandardOutput $fo -RedirectStandardError $fe -PassThru -WindowStyle Hidden
Write-Host "FAKE PID=$($fake.Id) scenario=$Scenario"
Start-Sleep -Seconds 3

$go = Join-Path $bin ("units_" + $Scenario + "_gui_out.log")
$ge = Join-Path $bin ("units_" + $Scenario + "_gui_err.log")
Remove-Item $go,$ge -ErrorAction SilentlyContinue
$gui = Start-Process -FilePath (Join-Path $bin "War3DeathSettlement.exe") `
    -ArgumentList "--name","fakewar3","--force-version","1.27.0.52240" -WorkingDirectory $bin `
    -RedirectStandardOutput $go -RedirectStandardError $ge -PassThru -WindowStyle Normal
Write-Host "GUI PID=$($gui.Id)"

$deadline = (Get-Date).AddSeconds(40)
$hwnd = [IntPtr]::Zero
while ((Get-Date) -lt $deadline) {
    if (-not (Get-Process -Id $gui.Id -ErrorAction SilentlyContinue)) { Fail "GUI exited early" }
    $hwnd = [W32U]::FindMain($gui.Id)
    if ($hwnd -ne [IntPtr]::Zero) { break }
    Start-Sleep -Milliseconds 300
}
if ($hwnd -eq [IntPtr]::Zero) { Fail "GUI main window not found" }
Write-Host "GUI HWND=$hwnd"
Start-Sleep -Seconds 18

$win = Get-WinElement $hwnd
$tabs = Get-TabNames $win
Write-Host ("TABS = {0}" -f ($tabs -join ' | '))
if ($tabs.Count -ne 3 -or $tabs -notcontains $TAB_UNITS) { Fail "expected 3 tabs incl. units tab, got: $($tabs -join ',')" }

Select-Tab $win $TAB_UNITS
Start-Sleep -Seconds 10

$win = Get-WinElement $hwnd
$grid = Find-TopGrid $win
if ($null -eq $grid) { Fail "units grid not found" }
$headers = Get-Headers $grid
Write-Host ("HEADERS = {0}" -f ($headers -join ' | '))
$SEP = [string][char]1
if (($headers -join $SEP) -ne ($EXPECT_HEADERS -join $SEP)) {
    Fail ("unit headers mismatch: " + ($headers -join ' | '))
}
Ok "15 columns in the required order"

$rows = Get-RowCount $grid
Write-Host "UNIT ROWS = $rows"
if ($rows -lt 5) { Fail "too few unit rows ($rows)" }

for ($r = 0; $r -lt [Math]::Min($rows, 6); $r++) {
    $line = @()
    for ($c = 0; $c -lt 15; $c++) { $line += (Get-CellText $grid $r $c) }
    Write-Host ("ROW[{0}] = {1}" -f $r, ($line -join ' | ').Replace("`r", " ").Replace("`n", "/"))
}

if ($Scenario -eq 'jass') {
    $numeric = 0; $heroRow = -1
    for ($r = 0; $r -lt $rows; $r++) {
        $range = Get-CellText $grid $r 2
        if ($range -match '^\d') { $numeric++ }
        if ($heroRow -lt 0) {
            $txt = Get-CellText $grid $r 1
            if ($txt.Contains($TITLE_UTH) -and $txt.Contains($NAME_PAL)) { $heroRow = $r }
        }
    }
    Write-Host "NUMERIC ROWS = $numeric / $rows (hero row = $heroRow)"
    if ($numeric -lt 5) { Fail "attribute columns are not filled (numeric rows=$numeric)" }
    if ($heroRow -lt 0) { Fail "no hero row carrying title+name in the name column" }
    $heroName = Get-CellText $grid $heroRow 1
    Write-Host ("HERO NAME CELL = {0}" -f $heroName.Replace("`r", " ").Replace("`n", " / "))
    Ok "hero row shows title + name; attribute columns have numbers"
    Shot-Window $hwnd (Join-Path $outdir ("{0}_01_units_numbers.png" -f $Scenario))
} else {
    $bad = 0; $checked = 0
    for ($r = 0; $r -lt $rows; $r++) {
        for ($c = 2; $c -le 12; $c++) {
            $v = Get-CellText $grid $r $c
            $checked++
            if ($v -ne '?') { $bad++; if ($bad -le 5) { Write-Host ("  attr not '?': row {0} col {1} = '{2}'" -f $r, $c, $v) } }
        }
    }
    Write-Host "ATTR CELLS = $checked, NOT-QUESTION = $bad"
    if ($checked -eq 0) { Fail "no attribute cell readable" }
    if ($bad -ne 0) { Fail "$bad attribute cell(s) are not '?' without JAPI" }
    Ok "without JAPI every attribute cell is '?'"
    Shot-Window $hwnd (Join-Path $outdir ("{0}_01_units_all_question.png" -f $Scenario))
}

# ---------------- header search: type code ----------------
$codeHeader = Find-Header $grid $HDR_CODE
if ($null -eq $codeHeader) { Fail "type-code header not found" }
Click-Element $codeHeader
Start-Sleep -Milliseconds 600
Set-SearchText "Hpal"
$win = Get-WinElement $hwnd
$grid = Find-TopGrid $win
$headers = Get-Headers $grid
$expectCode = "$HDR_CODE" + $LBRACKET + "Hpal" + $RBRACKET
Write-Host ("HEADERS[code-filter] = {0}" -f ($headers -join ' | '))
if ($headers -notcontains $expectCode) { Fail "type-code header does not show the filter indicator" }
$rowsFiltered = Get-RowCount $grid
Write-Host "ROWS AFTER code=Hpal : $rowsFiltered"
if ($rowsFiltered -lt 1) { Fail "type-code filter returned no rows" }
for ($r = 0; $r -lt $rowsFiltered; $r++) {
    if ((Get-CellText $grid $r 0) -ne "Hpal") { Fail "row $r does not match type code Hpal" }
}
Ok "type-code header search works"
Shot-Window $hwnd (Join-Path $outdir ("{0}_02_search_code.png" -f $Scenario))
Set-SearchText ""
$win = Get-WinElement $hwnd
$grid = Find-TopGrid $win
Write-Host "ROWS AFTER CLEAR: $(Get-RowCount $grid)"

# ---------------- header search: unit name column, keyword only in the hero TITLE ----------------
if ($Scenario -eq 'jass') {
    $nameHeader = Find-Header $grid $HDR_NAME
    if ($null -eq $nameHeader) { Fail "unit-name header not found" }
    Click-Element $nameHeader
    Start-Sleep -Milliseconds 600
    Set-SearchText $KW_TITLE
    $win = Get-WinElement $hwnd
    $grid = Find-TopGrid $win
    $headers = Get-Headers $grid
    $expectName = "$HDR_NAME" + $LBRACKET + $KW_TITLE + $RBRACKET
    Write-Host ("HEADERS[name-filter] = {0}" -f ($headers -join ' | '))
    if ($headers -notcontains $expectName) { Fail "name header does not show the filter indicator" }
    $titleRows = Get-RowCount $grid
    Write-Host "ROWS AFTER name~=title : $titleRows"
    if ($titleRows -ne 1) { Fail "title search should hit exactly the Hpal row ($titleRows)" }
    $hit = Get-CellText $grid 0 1
    Write-Host ("TITLE-SEARCH HIT = {0}" -f $hit.Replace("`r", " ").Replace("`n", " / "))
    if (-not ($hit.Contains($TITLE_UTH))) { Fail "title search hit does not contain the hero proper name" }
    Ok "name header search matches the hero title (first line)"
    Shot-Window $hwnd (Join-Path $outdir ("{0}_03_search_title.png" -f $Scenario))
    Set-SearchText ""
    $win = Get-WinElement $hwnd
    $grid = Find-TopGrid $win
    Write-Host "ROWS AFTER CLEAR: $(Get-RowCount $grid)"
}

Shot-Window $hwnd (Join-Path $outdir ("{0}_04_final.png" -f $Scenario))

# ---------------- ddh log ----------------
$ddhLog = Join-Path $bin ("hook\ddh-" + $fake.Id + ".log")
Write-Host "DDH LOG = $ddhLog"
if (Test-Path $ddhLog) {
    $attr = @(Select-String -Path $ddhLog -Pattern "ATTR" -ErrorAction SilentlyContinue)
    Write-Host ("DDH LOG ATTR lines = {0}" -f $attr.Count)
    $attr | Select-Object -First 16 | ForEach-Object { Write-Host ("  " + $_.Line) }
    $rounds = @(Select-String -Path $ddhLog -Pattern "ATTR round" -ErrorAction SilentlyContinue)
    Write-Host "DDH ATTR ROUNDS LOGGED = $($rounds.Count)"
    if ($attr.Count -lt 1) { Fail "ddh log has no ATTR lines" }
    if ($rounds.Count -lt 1) { Fail "ddh never processed an attribute request round" }
} else {
    Fail "ddh log not found: $ddhLog"
}

$gui.CloseMainWindow() | Out-Null
Start-Sleep -Seconds 2
if (-not $gui.HasExited) { Stop-Process -Id $gui.Id -Force -ErrorAction SilentlyContinue }
Stop-Process -Id $fake.Id -Force -ErrorAction SilentlyContinue
Remove-Item Env:FAKE_UNITS,Env:FAKE_IMMORTAL,Env:FAKE_AMP,Env:FAKE_NO_JASS -ErrorAction SilentlyContinue
Write-Host ("VERIFY_UNITS_PAGE DONE (" + $Scenario + ")")
exit 0
