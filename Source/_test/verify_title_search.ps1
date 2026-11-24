# verify_title_search.ps1 -- fakewar3 + GUI end-to-end for "search by hero title":
#   1) death-settlement page: click the unit-name header, type a hero TITLE -> only that hero (Hpal) rows remain
#   2) damage-events page: click the damage-source header, type the same TITLE -> only that hero's events remain
#   3) columns unchanged: settlement 14 (time + 13 data) / hook 18, no extra "title" column
# The title index is fed by the ddh v12 attribute responses (PollUnitAttrs), so the test first opens the
# battlefield-units page for a while (that page drives the polling), then switches to the other two pages.
#
# -FakeGame fakegame_title = a TEMP variant of the fake game (built from a copy of fakegame/ with the
#   "Propernames" stub returning 0) so ddh falls back to GetHeroProperName and hero titles differ per unit
#   (乌瑟尔 / 穆拉丁). The stock fakegame/ fixture answers Propernames with one constant string id, which
#   makes every unit's title identical - useless for a per-hero filter check. Nothing in the app or in the
#   real ddh/hook code is changed by this; -FakeGame fakegame runs the same script against the stock fixture.
# ASCII ONLY on purpose (Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI); all Chinese strings are
# built from code points at runtime.
param([string]$FakeGame = 'fakegame_title')
$ErrorActionPreference = 'Stop'

$test = $PSScriptRoot
$root = Split-Path -Parent $test
$fg   = Join-Path $test $FakeGame
$bin  = Join-Path $root "bin\Release\net10.0-windows"
$outdir = Join-Path $test "title_search"
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
  public static void Click(int x, int y) {
    SetCursorPos(x, y); System.Threading.Thread.Sleep(80);
    mouse_event(0x02,0,0,0,IntPtr.Zero); mouse_event(0x04,0,0,0,IntPtr.Zero);
  }
}
"@

function T([int[]]$cp) { -join ($cp | ForEach-Object { [char]$_ }) }

# tab captions: death-settlement / damage-events / battlefield-units
$TAB_SETTLE = T @(0x6B7B,0x4EA1,0x7ED3,0x7B97)
$TAB_HOOK   = T @(0x4F24,0x5BB3,0x4E8B,0x4EF6)
$TAB_UNITS  = T @(0x6218,0x573A,0x5355,0x4F4D)
# headers
$HDR_NAME   = T @(0x5355,0x4F4D,0x540D)                    # unit name
$HDR_CODE   = T @(0x7C7B,0x578B,0x7801)                    # type code
$HDR_SRC    = T @(0x4F24,0x5BB3,0x6765,0x6E90)             # damage source
# fake-game hero data for Hpal
$TITLE_UTH  = T @(0x4E4C,0x745F,0x5C14)                    # hero title (fake JASS proper name)
$NAME_PAL   = T @(0x5723,0x9A91,0x58EB)                    # unit name  (fake JASS unit name)
$KW_TITLE   = T @(0x4E4C,0x745F)                           # title keyword (2 chars)
$KW_NONE    = T @(0x5251,0x5723)                           # a title/value no unit has
$WORD_TITLE = T @(0x79F0,0x8C13)                           # "cheng wei": the word a NEW column would use
$LBRACKET   = T @(0xFF08,0x2315,0x20)                      # full-width "(" + search glyph + space
$RBRACKET   = T @(0xFF09)                                  # full-width ")"

# expected header lists (must be EXACTLY the pre-change layout: no new column)
$EXPECT_SETTLE = @(
  (T @(0x65F6,0x95F4)),                                     # time
  $HDR_NAME,
  $HDR_CODE,
  (T @(0x5355,0x4F4D,0x49,0x44)),                           # unit id
  (T @(0x62E5,0x6709,0x8005)),                              # owner
  (T @(0x7ED3,0x5C40)),                                     # kind
  (T @(0x5B9E,0x4F8B)),                                     # instance
  (T @(0x53D7,0x51FB)),                                     # hits
  (T @(0x603B,0x4F24,0x5BB3)),                              # total damage
  (T @(0x6700,0x5927,0x5355,0x6B21)),                       # max single hit
  (T @(0x6700,0x60E8,0x31,0x79D2)),                         # worst 1 second
  (T @(0x79D2,0x4F24)),                                     # dps
  (T @(0x5B58,0x6D3B,0x73)),                                # lifetime s
  (T @(0x6218,0x6597,0x73))                                 # combat s
)
$EXPECT_HOOK = @(
  (T @(0x65F6,0x95F4)),                                     # time
  (T @(0x89E6,0x53D1,0x5355,0x4F4D)),                       # victim
  (T @(0x89E6,0x53D1,0x5355,0x4F4D,0x49,0x44)),             # victim id
  (T @(0x89E6,0x53D1,0x5355,0x4F4D,0x73A9,0x5BB6)),         # victim player
  $HDR_SRC,
  (T @(0x4F24,0x5BB3,0x6765,0x6E90,0x49,0x44)),             # source id
  (T @(0x4F24,0x5BB3,0x6765,0x6E90,0x73A9,0x5BB6)),         # source player
  (T @(0x5C42)),                                            # depth
  (T @(0x539F,0x59CB,0x4F24,0x5BB3)),                       # raw damage
  (T @(0x5F15,0x64CE,0x4F24,0x5BB3)),                       # engine damage
  (T @(0x5730,0x56FE,0x4F24,0x5BB3)),                       # map damage
  (T @(0x51C0,0x6389,0x8840)),                              # net hp drop
  (T @(0x500D,0x6570)),                                     # multiplier
  (T @(0x672C,0x5C42,0x524D,0x8840,0x2192,0x540E,0x8840)),  # hp before -> after
  (T @(0x653B,0x51FB)),                                     # is attack
  (T @(0x8FDC,0x7A0B)),                                     # is ranged
  (T @(0x653B,0x51FB,0x7C7B,0x578B)),                       # attack type
  (T @(0x4F24,0x5BB3,0x7C7B,0x578B))                        # damage type
)

function Fail([string]$msg) { Write-Host "FAIL: $msg"; throw $msg }
function Ok([string]$msg)  { Write-Host "PASS: $msg" }

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
    if ($hwnd -eq [IntPtr]::Zero) { return }
    [W32T]::ShowWindow($hwnd, 9) | Out-Null
    [W32T]::SetWindowPos($hwnd, [IntPtr](-1), 0, 0, 0, 0, 0x0001 -bor 0x0002 -bor 0x0040) | Out-Null
    [W32T]::SetForegroundWindow($hwnd) | Out-Null
    Start-Sleep -Milliseconds 400
}

# UI Automation only exposes a tab page's grid once that page is selected AND the window is on screen;
# both are racy in a script-driven session, so retry (re-selecting the tab / re-focusing) for a while.
function Wait-Grid([IntPtr]$hwnd, [string]$tabName, [int]$tries = 25) {
    for ($i = 0; $i -lt $tries; $i++) {
        Focus-Win $script:guiPid
        $win = Get-WinElement $hwnd
        $grid = Find-TopGrid $win
        if ($null -ne $grid) { return $grid }
        if (($i % 4) -eq 3) {
            $win = Get-WinElement $hwnd
            Select-Tab $win $tabName
        }
        Start-Sleep -Seconds 1
    }
    return $null
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
    Start-Sleep -Milliseconds 1200
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
    if ($null -eq $best) {
        # A window covered by another window may report IsOffscreen=true; fall back to size only.
        for ($i = 0; $i -lt $grids.Count; $i++) {
            $e = $grids.Item($i)
            $r = $e.Current.BoundingRectangle
            if ($r.Width -le 100 -or $r.Height -le 50) { continue }
            if ($r.Top -lt $bestTop) { $best = $e; $bestTop = $r.Top }
        }
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
    [W32T]::Click([int]($r.Left + $r.Width / 2), [int]($r.Top + $r.Height / 2))
}

# Set the header search box text. Prefer UIA ValuePattern (no focus/SendKeys needed, works in
# script-driven sessions); fall back to clipboard + Ctrl+V.
function Set-SearchText($grid, [string]$text) {
    $editCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Edit)
    $editEl = $grid.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $editCond)
    if ($null -ne $editEl) {
        try {
            $vp = $editEl.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)
            $vp.SetValue($text)
            Start-Sleep -Milliseconds 1200
            Write-Host "  (search box set via ValuePattern: '$text')"
            return
        } catch {
            Write-Host ("  (ValuePattern failed: " + $_.Exception.Message + " -> SendKeys fallback)")
        }
    } else {
        Write-Host "  (no Edit element under the grid -> SendKeys fallback)"
    }
    if ($text.Length -gt 0) { Set-Clipboard -Value $text }
    [System.Windows.Forms.SendKeys]::SendWait("^a")
    Start-Sleep -Milliseconds 150
    if ($text.Length -gt 0) { [System.Windows.Forms.SendKeys]::SendWait("^v") }
    else { [System.Windows.Forms.SendKeys]::SendWait("{BACKSPACE}") }
    Start-Sleep -Milliseconds 1200
}

function Assert-Headers($grid, [string[]]$expect, [string]$where) {
    $headers = Get-Headers $grid
    Write-Host ("HEADERS[{0}] = {1}" -f $where, ($headers -join ' | '))
    $SEP = [string][char]1
    if (($headers -join $SEP) -ne ($expect -join $SEP)) {
        Fail ("{0} header layout changed: {1}" -f $where, ($headers -join ' | '))
    }
    if (($headers -join ' ').Contains($WORD_TITLE)) { Fail "$where has an extra title column" }
    Ok ("{0}: {1} columns, same layout as before (no extra title column)" -f $where, $headers.Count)
    return ,$headers
}

# Open the header search box of the given column (clicking it again re-opens after a screenshot
# moved the focus away and committed the previous keyword).
function Invoke-HeaderSearch($grid, [string]$prefix) {
    Focus-Win $script:guiPid
    $hdr = Find-Header $grid $prefix
    if ($null -eq $hdr) { Fail "header not found: $prefix" }
    Click-Element $hdr
    Start-Sleep -Milliseconds 700
}

# ---------------- scenario ----------------
$env:FAKE_UNITS = '24'
$env:FAKE_IMMORTAL = '0'
# amp=10 -> the fake's damage is 10% of normal: units live long enough for the attribute polling
# (1/s) to learn their titles before they die, and deaths/respawns stay spread out.
$env:FAKE_AMP = '10'
Remove-Item Env:FAKE_NO_JASS -ErrorAction SilentlyContinue
Remove-Item Env:FAKE_NO_RESPAWN -ErrorAction SilentlyContinue
$fo = Join-Path $fg "title_fake_out.log"; $fe = Join-Path $fg "title_fake_err.log"
Remove-Item $fo,$fe -ErrorAction SilentlyContinue
$fake = Start-Process -FilePath (Join-Path $fg "fakewar3.exe") -ArgumentList "300" -WorkingDirectory $fg `
    -RedirectStandardOutput $fo -RedirectStandardError $fe -PassThru -WindowStyle Hidden
Write-Host "FAKE PID=$($fake.Id)"
Start-Sleep -Seconds 3

# hook_enable=1: ddh is what brings the hero titles (v12 attribute responses).
$ini = Join-Path $bin "War3DeathSettlement.ini"
@"
interval_ms=50
auto_attach=1
read_plugin_log=0
hook_enable=1
"@ | Set-Content -Path $ini -Encoding UTF8

$logDir = Join-Path $bin "logs"
$testStart = Get-Date
$go = Join-Path $bin "title_gui_out.log"; $ge = Join-Path $bin "title_gui_err.log"
Remove-Item $go,$ge -ErrorAction SilentlyContinue
# --pid: pin to the FAKE game (a real War3.exe may be running on this machine; never touch it).
$gui = Start-Process -FilePath (Join-Path $bin "War3DeathSettlement.exe") `
    -ArgumentList "--pid", $fake.Id, "--force-version", "1.27.0.52240" -WorkingDirectory $bin `
    -RedirectStandardOutput $go -RedirectStandardError $ge -PassThru -WindowStyle Normal
Write-Host "GUI PID=$($gui.Id)"
$script:guiPid = $gui.Id

try {

$deadline = (Get-Date).AddSeconds(40)
$hwnd = [IntPtr]::Zero
while ((Get-Date) -lt $deadline) {
    if (-not (Get-Process -Id $gui.Id -ErrorAction SilentlyContinue)) { Fail "GUI exited early" }
    $hwnd = [W32T]::FindMain($gui.Id)
    if ($hwnd -ne [IntPtr]::Zero) { break }
    Start-Sleep -Milliseconds 300
}
if ($hwnd -eq [IntPtr]::Zero) { Fail "GUI main window not found" }
Write-Host "GUI HWND=$hwnd"

# make sure it attached to the FAKE process (not to the real War3.exe)
$pidOk = $false
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 700
    $newLogs = @(Get-ChildItem $logDir -Filter "dss-*.log" -ErrorAction SilentlyContinue |
                 Where-Object { $_.LastWriteTime -ge $testStart.AddSeconds(-2) })
    foreach ($lf in $newLogs) {
        if (Select-String -Path $lf.FullName -Pattern ("PID " + $fake.Id) -Quiet -ErrorAction SilentlyContinue) { $pidOk = $true }
    }
    if ($pidOk) { break }
}
if (-not $pidOk) { Fail "GUI did not attach to the fake game (PID $($fake.Id))" }
Ok "GUI attached to the fake game (PID $($fake.Id))"

Start-Sleep -Seconds 3

$win = Get-WinElement $hwnd
$tabs = Get-TabNames $win
Write-Host ("TABS = {0}" -f ($tabs -join ' | '))
if ($tabs.Count -ne 3 -or $tabs -notcontains $TAB_SETTLE -or $tabs -notcontains $TAB_HOOK -or $tabs -notcontains $TAB_UNITS) {
    Fail "expected three tabs, got: $($tabs -join ',')"
}

# ---- phase 1: battlefield-units page drives the ddh attribute polling -> the title index gets filled ----
# 40s: long enough for most alive units to be polled at least once (and for several deaths/respawns).
Select-Tab $win $TAB_UNITS
Start-Sleep -Seconds 40
$unitsGrid = Wait-Grid $hwnd $TAB_UNITS
if ($null -eq $unitsGrid) { Fail "units grid not found" }
$uRows = Get-RowCount $unitsGrid
Write-Host "UNIT ROWS (polling window) = $uRows"
if ($uRows -lt 5) { Fail "too few unit rows on the units page ($uRows)" }
Shot-Window $hwnd (Join-Path $outdir "01_units_title_source.png")

# The app itself logs every newly learned title (throttled to 10): its log must carry the hero title,
# which is what the settlement/event searches use (the index is fed by ddh's attribute responses).
$PAT_TITLE_INDEX = T @(0x79F0,0x8C13,0x7D22,0x5F15)   # "title index" words in the app log line
$guiLog = Get-ChildItem $logDir -Filter "dss-*.log" -ErrorAction SilentlyContinue |
          Where-Object { $_.LastWriteTime -ge $testStart.AddSeconds(-2) } |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($null -eq $guiLog) { Fail "GUI log not found" }
$titleHits = @(Select-String -Path $guiLog.FullName -Pattern ($PAT_TITLE_INDEX + ".*" + $TITLE_UTH) -Encoding UTF8 -ErrorAction SilentlyContinue)
Write-Host ("APP LOG TITLE HITS = {0}" -f $titleHits.Count)
if ($titleHits.Count -lt 1) {
    $indexLines = @(Select-String -Path $guiLog.FullName -Pattern $PAT_TITLE_INDEX -Encoding UTF8 -ErrorAction SilentlyContinue)
    Write-Host ("APP LOG {0} lines = {1}" -f $PAT_TITLE_INDEX, $indexLines.Count)
    $indexLines | Select-Object -First 5 | ForEach-Object { Write-Host ("  " + $_.Line) }
    Fail "the app never indexed the hero title ($TITLE_UTH)"
}
Write-Host ("  " + $titleHits[0].Line)
Ok ("app log: hero title ({0}) is in the address->title index" -f $TITLE_UTH)

# ---- phase 2: death-settlement page -> search by the hero TITLE ----
Select-Tab $win $TAB_SETTLE
Start-Sleep -Seconds 15
$grid = Wait-Grid $hwnd $TAB_SETTLE
if ($null -eq $grid) { Fail "settlement grid not found" }
$headers = Assert-Headers $grid $EXPECT_SETTLE "settlement"

$rowsBefore = Get-RowCount $grid
Write-Host "SETTLE ROWS before filter = $rowsBefore"
if ($rowsBefore -lt 2) { Fail "too few settlement/live rows to verify the filter ($rowsBefore)" }

Invoke-HeaderSearch $grid $HDR_NAME
Set-SearchText $grid $KW_TITLE
$win = Get-WinElement $hwnd
$grid2 = Find-TopGrid $win
if ($null -ne $grid2) { $grid = $grid2 }
$headers = Get-Headers $grid
$expectName = $HDR_NAME + $LBRACKET + $KW_TITLE + $RBRACKET
Write-Host ("HEADERS[settlement filtered] = {0}" -f ($headers -join ' | '))
if ($headers -notcontains $expectName) { Fail "unit-name header does not show the filter indicator '$expectName'" }

$rowsAfter = Get-RowCount $grid
Write-Host "SETTLE ROWS after title filter = $rowsAfter (before $rowsBefore)"
if ($rowsAfter -lt 1) { Fail "title search returned no settlement rows" }
if ($rowsAfter -ge $rowsBefore) { Fail "title search did not narrow the table ($rowsBefore -> $rowsAfter)" }
Ok "settlement search by hero title narrows the table ($rowsBefore -> $rowsAfter) - see the screenshot"
Shot-Window $hwnd (Join-Path $outdir "02_settlement_title_search.png")

# clear the filter
Invoke-HeaderSearch $grid $HDR_NAME
Set-SearchText $grid ""
$win = Get-WinElement $hwnd
$grid2 = Find-TopGrid $win
if ($null -ne $grid2) { $grid = $grid2 }
$headers = Get-Headers $grid
if ($headers -contains $expectName) { Fail "settlement filter indicator was not cleared" }
Write-Host "SETTLE ROWS after clear = $(Get-RowCount $grid)"

# ---- phase 3: damage-events page -> search the source column by the hero TITLE ----
Select-Tab $win $TAB_HOOK
Start-Sleep -Seconds 3
$grid = Wait-Grid $hwnd $TAB_HOOK
if ($null -eq $grid) { Fail "hook grid not found" }
$headers = Assert-Headers $grid $EXPECT_HOOK "hook"

$hookBefore = Get-RowCount $grid
Write-Host "HOOK ROWS before filter = $hookBefore"
if ($hookBefore -lt 5) { Fail "too few damage events ($hookBefore)" }

Invoke-HeaderSearch $grid $HDR_SRC
Set-SearchText $grid $KW_TITLE
$win = Get-WinElement $hwnd
$grid2 = Find-TopGrid $win
if ($null -ne $grid2) { $grid = $grid2 }
$headers = Get-Headers $grid
$expectSrc = $HDR_SRC + $LBRACKET + $KW_TITLE + $RBRACKET
Write-Host ("HEADERS[hook filtered] = {0}" -f ($headers -join ' | '))
if ($headers -notcontains $expectSrc) { Fail "damage-source header does not show the filter indicator '$expectSrc'" }

$hookAfter = Get-RowCount $grid
Write-Host "HOOK ROWS after title filter = $hookAfter (before $hookBefore)"
if ($hookAfter -lt 1) { Fail "source-title search returned no events" }
if ($hookAfter -ge $hookBefore) { Fail "source-title search did not narrow the table ($hookBefore -> $hookAfter)" }
Ok "damage-event source search by hero title narrows the table ($hookBefore -> $hookAfter) - see the screenshot"
Shot-Window $hwnd (Join-Path $outdir "03_hook_source_title_search.png")

# negative control: a title nobody has -> 0 rows
Invoke-HeaderSearch $grid $HDR_SRC
Set-SearchText $grid $KW_NONE
$win = Get-WinElement $hwnd
$grid2 = Find-TopGrid $win
if ($null -ne $grid2) { $grid = $grid2 }
$noneRows = Get-RowCount $grid
Write-Host "HOOK ROWS for a non-existent title = $noneRows"
if ($noneRows -ne 0) { Fail "searching a non-existent title kept $noneRows event rows" }
Ok "non-existent title returns 0 rows (no false positives)"

Shot-Window $hwnd (Join-Path $outdir "04_hook_no_match.png")

# ---------------- cleanup (own processes only; never touch the real War3.exe) ----------------
} finally {
    if ($null -ne $gui) {
        try { $gui.CloseMainWindow() | Out-Null } catch { }
        Start-Sleep -Seconds 1
        if (-not $gui.HasExited) { Stop-Process -Id $gui.Id -Force -ErrorAction SilentlyContinue }
    }
    if ($null -ne $fake -and -not $fake.HasExited) { Stop-Process -Id $fake.Id -Force -ErrorAction SilentlyContinue }
    Remove-Item Env:FAKE_UNITS,Env:FAKE_IMMORTAL,Env:FAKE_AMP,Env:FAKE_NO_JASS -ErrorAction SilentlyContinue
}
Write-Host "VERIFY_TITLE_SEARCH DONE"
exit 0
