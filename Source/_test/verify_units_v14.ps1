# verify_units_v14.ps1 -- fakewar3 + GUI regression for the v14 battlefield-units page:
#   * exactly 15 columns: 类型码/名称/攻击范围/攻击力/攻击间隔/护甲/移速/白天视野/夜晚视野/
#     主动攻击范围/力/敏/智/拥有者/地址   (no 单位附加值)
#   * day/night sight come from jass.slk (fake EXExecuteScript returns 1500 / 900)
#   * the Aloc dummy (e04F) is filtered out (12 fake units -> 11 rows)
#   * the old idle-cleanup is gone: with DSS_IDLE_MINUTES=0.05 (ignored now) only unit 0
#     takes damage, yet the row count stays at 11 for 60 seconds.
# ASCII ONLY (Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI); Chinese is built from
# code points at runtime.
$ErrorActionPreference = 'Stop'

$test = $PSScriptRoot
$root = Split-Path -Parent $test
$fg   = Join-Path $test "fakegame"
$bin  = Join-Path $root "bin\Release\net10.0-windows"
$outdir = Join-Path $test "units_v14"
New-Item -ItemType Directory -Force -Path $outdir | Out-Null

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W32V14 {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdc, uint flags);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmd);
  [DllImport("user32.dll")] public static extern bool UpdateWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
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
}
"@

function T([int[]]$cp) { -join ($cp | ForEach-Object { [char]$_ }) }
function Fail([string]$msg) { Write-Host "FAIL: $msg"; throw $msg }
function Ok([string]$msg)  { Write-Host "PASS: $msg" }

$TAB_UNITS = T @(0x6218,0x573A,0x5355,0x4F4D)
$HDR_CODE  = T @(0x7C7B,0x578B,0x7801)
$HDR_NAME  = T @(0x5355,0x4F4D,0x540D,0x79F0,0xFF08,0x79F0,0x8C13,0xFF09)
$HDR_OWNER = T @(0x62E5,0x6709,0x8005)
$HDR_ADDR  = T @(0x5730,0x5740)
$EXPECT_HEADERS = @(
  $HDR_CODE, $HDR_NAME,
  (T @(0x653B,0x51FB,0x8303,0x56F4)),
  (T @(0x653B,0x51FB,0x529B)),
  (T @(0x653B,0x51FB,0x95F4,0x9694)),
  (T @(0x62A4,0x7532)),
  (T @(0x79FB,0x901F)),
  (T @(0x767D,0x5929,0x89C6,0x91CE)),
  (T @(0x591C,0x665A,0x89C6,0x91CE)),
  (T @(0x4E3B,0x52A8,0x653B,0x51FB,0x8303,0x56F4)),
  (T @(0x529B,0x91CF)),
  (T @(0x654F,0x6377)),
  (T @(0x667A,0x529B)),
  $HDR_OWNER, $HDR_ADDR
)

function Shot-Window([IntPtr]$hwnd, [string]$Out) {
    [W32V14]::SetForegroundWindow($hwnd) | Out-Null
    Start-Sleep -Milliseconds 800
    $r = New-Object W32V14+RECT; [W32V14]::GetWindowRect($hwnd, [ref]$r) | Out-Null
    $w = $r.Right - $r.Left; $h = $r.Bottom - $r.Top
    if ($w -le 0 -or $h -le 0) { $w = 1280; $h = 800 }
    $bmp = New-Object System.Drawing.Bitmap($w, $h); $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($r.Left, $r.Top, 0, 0, (New-Object System.Drawing.Size($w, $h)))
    $g.Dispose()
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
    Start-Sleep -Milliseconds 1500
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

function Find-UnitsGrid($win, $expectedHeaders) {
    $sep = [string][char]1
    $want = $expectedHeaders -join $sep
    $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::DataGrid)
    $grids = $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
    for ($i = 0; $i -lt $grids.Count; $i++) {
        $g = $grids.Item($i)
        try {
            $h = Get-Headers $g
            if (($h -join $sep) -eq $want) { return $g }
        } catch { }
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
        if ($null -ne $item) {
            try {
                $vp = $item.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)
                $v = $vp.Current.Value
                if ($null -ne $v -and $v -ne '') { return [string]$v }
            } catch { }
            try {
                $lp = $item.GetCurrentPattern([System.Windows.Automation.LegacyIAccessiblePattern]::Pattern)
                $lv = $lp.Current.Value
                if ($null -ne $lv -and $lv -ne '') { return [string]$lv }
            } catch { }
            return $item.Current.Name
        }
    } catch { }
    return ""
}

function Get-LogLines([string]$path, [string]$pattern) {
    if (-not (Test-Path $path)) { return @() }
    return @(Get-Content -Path $path -Encoding Default -ErrorAction SilentlyContinue |
             Where-Object { $_ -match $pattern })
}

# ---------------- start fake game / GUI ----------------
Get-Process fakewar3_v14 -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process War3DeathSettlement -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1
$env:FAKE_UNITS = '12'
$env:FAKE_IMMORTAL = '1'
$env:FAKE_LOCUST = '1'
$env:FAKE_NO_KILL = '1'
$env:FAKE_DAMAGE_ONE = '1'
Remove-Item Env:FAKE_NO_DAMAGE -ErrorAction SilentlyContinue
Remove-Item Env:FAKE_NO_SLK -ErrorAction SilentlyContinue
# old versions honoured this env; v14 ignores it completely
$env:DSS_IDLE_MINUTES = '0.05'

$fakeExe = Join-Path $fg "fakewar3_v14.exe"
Copy-Item (Join-Path $fg "fakewar3.exe") $fakeExe -Force
$fo = Join-Path $fg "v14_units_out.log"; $fe = Join-Path $fg "v14_units_err.log"
Remove-Item $fo,$fe -ErrorAction SilentlyContinue
$fake = Start-Process -FilePath $fakeExe -ArgumentList "300" -WorkingDirectory $fg `
    -RedirectStandardOutput $fo -RedirectStandardError $fe -PassThru -WindowStyle Hidden
Write-Host "FAKE PID=$($fake.Id)"
Start-Sleep -Seconds 3

$go = Join-Path $bin "v14_units_gui_out.log"; $ge = Join-Path $bin "v14_units_gui_err.log"
Remove-Item $go,$ge -ErrorAction SilentlyContinue
$gui = Start-Process -FilePath (Join-Path $bin "War3DeathSettlement.exe") `
    -ArgumentList "--pid",$fake.Id,"--force-version","1.27.0.52240" -WorkingDirectory $bin `
    -RedirectStandardOutput $go -RedirectStandardError $ge -PassThru -WindowStyle Normal
Write-Host "GUI PID=$($gui.Id)"

try {
    $deadline = (Get-Date).AddSeconds(45)
    $hwnd = [IntPtr]::Zero
    while ((Get-Date) -lt $deadline) {
        if (-not (Get-Process -Id $gui.Id -ErrorAction SilentlyContinue)) { Fail "GUI exited early" }
        $hwnd = [W32V14]::FindMain($gui.Id)
        if ($hwnd -ne [IntPtr]::Zero) { break }
        Start-Sleep -Milliseconds 300
    }
    if ($hwnd -eq [IntPtr]::Zero) { Fail "GUI main window not found" }
    Write-Host "GUI HWND=$hwnd"

    Start-Sleep -Seconds 16
    $win = Get-WinElement $hwnd
    Select-Tab $win $TAB_UNITS
    Start-Sleep -Seconds 12

    $win = Get-WinElement $hwnd
    $grid = $null
    for ($try = 0; $try -lt 12 -and $null -eq $grid; $try++) {
        Start-Sleep -Seconds 1
        $win = Get-WinElement $hwnd
        $grid = Find-UnitsGrid $win $EXPECT_HEADERS
    }
    if ($null -eq $grid) {
        $tabs = @()
        try {
            $tc = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)
            $te = $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, $tc)
            for ($i = 0; $i -lt $te.Count; $i++) { $tabs += $te.Item($i).Current.Name }
        } catch { }
        Write-Host ("WINDOW TITLE = " + $win.Current.Name)
        Write-Host ("TABS = " + ($tabs -join ' | '))
        Fail "units grid not found"
    }

    $headers = Get-Headers $grid
    Write-Host ("HEADERS = {0}" -f ($headers -join ' | '))
    $SEP = [string][char]1
    if (($headers -join $SEP) -ne ($EXPECT_HEADERS -join $SEP)) {
        for ($i = 0; $i -lt [Math]::Max($headers.Count, $EXPECT_HEADERS.Count); $i++) {
            $a = if ($i -lt $headers.Count) { $headers[$i] } else { '<none>' }
            $b = if ($i -lt $EXPECT_HEADERS.Count) { $EXPECT_HEADERS[$i] } else { '<none>' }
            $ac = ($a.ToCharArray() | ForEach-Object { '{0:X4}' -f [int]$_ }) -join ' '
            $bc = ($b.ToCharArray() | ForEach-Object { '{0:X4}' -f [int]$_ }) -join ' '
            Write-Host ("HDR[{0}] actual len={1} [{2}] expected len={3} [{4}]" -f $i, $a.Length, $ac, $b.Length, $bc)
        }
        Fail ("unit headers mismatch: " + ($headers -join ' | '))
    }
    Ok "15 columns in the v14 order (day/night sight, no extra-value column)"

    $rows = Get-RowCount $grid
    for ($c = 0; $c -lt 17; $c++) { Write-Host ("CELL[0,{0}]='{1}'" -f $c, (Get-CellText $grid 0 $c)) }
    Write-Host "UNIT ROWS = $rows (expect 11: 12 fake units - 1 Aloc dummy)"
    if ($rows -ne 11) { Fail "expected 11 rows after locust filtering, got $rows" }

    $locust = 0; $dayNight = 0
    for ($r = 0; $r -lt $rows; $r++) {
        $code = Get-CellText $grid $r 0
        $name = Get-CellText $grid $r 1
        if ($code -eq "e04F" -or $name.Contains((T @(0x8757,0x866B)))) { $locust++ }
        $day = Get-CellText $grid $r 7
        $night = Get-CellText $grid $r 8
        if ($day -eq "1500" -and $night -eq "900") { $dayNight++ }
        if ($r -lt 4) { Write-Host ("ROW[{0}] {1} | {2} | day={3} night={4}" -f $r, $code, ($name -replace "`r", " " -replace "`n", "/"), $day, $night) }
    }
    Write-Host "LOCUST ROWS = $locust, DAY/NIGHT 1500/900 ROWS = $dayNight"
    if ($locust -ne 0) { Fail "locust unit(s) still visible in the units table" }
    if ($dayNight -lt 3) { Fail "day/night sight not read from jass.slk (only $dayNight rows show 1500/900)" }
    Ok "locust unit e04F hidden; day/night sight columns = 1500/900 from jass.slk"

    # ---------------- 60 s retention: only unit 0 takes damage, old idle cleanup env is set ----------------
    $rows0 = Get-RowCount $grid
    Write-Host "RETENTION t+0 rows=$rows0; waiting 60 s (DSS_IDLE_MINUTES=0.05 is intentionally set)"
    Start-Sleep -Seconds 60
    [W32V14]::SetForegroundWindow($hwnd) | Out-Null
    Start-Sleep -Milliseconds 500
    $win = Get-WinElement $hwnd
    $grid60 = Find-UnitsGrid $win $EXPECT_HEADERS
    if ($null -eq $grid60) {
        Write-Host "Find-UnitsGrid returned null after 60 s; reusing the original grid element"
        $grid60 = $grid
    }
    $rows60 = Get-RowCount $grid60
    Write-Host "RETENTION t+60 rows=$rows60"
    if ($rows60 -ne $rows0) { Fail "unit rows changed over 60 s ($rows0 -> $rows60): idle cleanup still active?" }
    if ($rows60 -lt 10) { Fail "too few rows after 60 s ($rows60)" }
    Ok "unit rows stable at $rows60 for 60 s with no deaths and no idle-cleanup removal"
    try {
        $shot = Join-Path $outdir "v14_units_retention_60s.png"
        Shot-Window $hwnd $shot
        Copy-Item $shot (Join-Path $outdir "v14_units_columns.png") -Force
    } catch { Write-Host "SHOT FAILED: $_" }

    # ---------------- logs ----------------
    $ddhLog = Join-Path $bin ("hook\ddh-" + $fake.Id + ".log")
    $ddhSight = Get-LogLines $ddhLog 'jass\.slk|nsight|sight'
    $ddhLocust = Get-LogLines $ddhLog 'e04F|0x100000'
    Write-Host "DDH LOG = $ddhLog"
    Write-Host "DDH sight lines = $($ddhSight.Count), locust lines = $($ddhLocust.Count)"
    $ddhLocust | Select-Object -First 6 | ForEach-Object { Write-Host ("  " + $_) }
    if ($ddhSight.Count -lt 1) { Fail "ddh log has no jass.slk sight lines" }
    if ($ddhLocust.Count -lt 1) { Fail "ddh log has no attr-locust (e04F / 0x100000) line" }

    $appLog = Get-ChildItem (Join-Path $bin "logs") -Filter "dss-*.log" -ErrorAction SilentlyContinue |
              Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($appLog) {
        $filters = Get-LogLines $appLog.FullName 'e04F|0x100000'
        Write-Host "APP LOG = $($appLog.FullName)"
        Write-Host "APP locust-filter lines = $($filters.Count)"
        $filters | Select-Object -First 6 | ForEach-Object { Write-Host ("  " + $_) }
        if ($filters.Count -lt 1) { Fail "app log has no 'battlefield units filtered: locust' line" }
    } else {
        Fail "app log not found under $bin\logs"
    }

    $ini = Join-Path $bin "War3DeathSettlement.ini"
    if (Test-Path $ini) {
        $idle = Select-String -Path $ini -Pattern 'idle_minutes' -ErrorAction SilentlyContinue
        if ($idle) { Fail "ini still writes idle_minutes" }
        Ok "ini no longer contains idle_minutes"
    }
}
finally {
    try { if (-not $gui.HasExited) { $gui.CloseMainWindow() | Out-Null; Start-Sleep -Seconds 2 } } catch { }
    try { if (-not $gui.HasExited) { Stop-Process -Id $gui.Id -Force -ErrorAction SilentlyContinue } } catch { }
    try { Stop-Process -Id $fake.Id -Force -ErrorAction SilentlyContinue } catch { }
    Get-Process fakewar3_v14 -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Remove-Item Env:FAKE_UNITS,Env:FAKE_IMMORTAL,Env:FAKE_LOCUST,Env:FAKE_NO_KILL,Env:FAKE_DAMAGE_ONE,Env:DSS_IDLE_MINUTES -ErrorAction SilentlyContinue
}

Write-Host "VERIFY_UNITS_V14 DONE"
exit 0
