# stress_reentry.ps1 -- 压测「伤害事件」页筛选框重入（真机崩溃复现/回归）。
$ErrorActionPreference = 'Continue'

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Drawing

# 截图用的 P/Invoke（闭合标记必须顶格）
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class StressShot {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left,Top,Right,Bottom; }
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
}
"@

$test = $PSScriptRoot
$root = Split-Path -Parent $test          # DeathSettlement
$fg   = Join-Path $test "fakegame"
$bin  = Join-Path $root "publish"         # 用 publish 产物跑，日志落 publish\logs

$uia = [System.Windows.Automation.AutomationElement]

function Get-DssLogs {
    return Get-ChildItem (Join-Path $bin "logs\dss-*.log") -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
}

function Select-ComboItem($combo, [int]$index) {
    $condItem = New-Object System.Windows.Automation.PropertyCondition($uia::ControlTypeProperty, [System.Windows.Automation.ControlType]::ListItem)
    $ecp = $null
    try {
        $ecp = $combo.GetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern)
        $ecp.Expand()
        Start-Sleep -Milliseconds 150
        $items = $combo.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condItem)
        if ($items.Count -gt $index) {
            $items[$index].GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
            return $true
        }
        return $false
    } catch { return $false }
    finally {
        try { $combo.GetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern).Collapse() } catch { }
    }
}

function Find-MainWindowElement([int]$procId) {
    $root = $uia::RootElement
    $all = $root.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition)
    foreach ($w in $all) {
        if ($w.Current.ProcessId -eq $procId -and $w.Current.NativeWindowHandle -ne 0) {
            if ($w.Current.Name -match 'War3DeathSettlement') { return $w }
        }
    }
    foreach ($w in $all) {
        if ($w.Current.ProcessId -eq $procId -and $w.Current.NativeWindowHandle -ne 0) { return $w }
    }
    return $null
}

function Shot([int]$procId, [string]$out) {
    try {
        $proc = Get-Process -Id $procId -ErrorAction Stop
        $h = $proc.MainWindowHandle
        if ($h -eq 0) { Write-Host "SHOT_FAIL nohwnd"; return }
        [StressShot]::ShowWindow($h, 9) | Out-Null
        [StressShot]::SetForegroundWindow($h) | Out-Null
        Start-Sleep -Milliseconds 600
        $r = New-Object StressShot+RECT
        [StressShot]::GetWindowRect($h, [ref]$r) | Out-Null
        $w = $r.Right - $r.Left; $hh = $r.Bottom - $r.Top
        if ($w -le 0 -or $hh -le 0) { $w = 1280; $hh = 800 }
        $bmp = New-Object System.Drawing.Bitmap($w, $hh)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $hdc = $g.GetHdc()
        [StressShot]::PrintWindow($h, $hdc, 2) | Out-Null
        $g.ReleaseHdc($hdc); $g.Dispose()
        $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
        Write-Host "SHOT $out (${w}x${hh})"
    } catch { Write-Host "SHOT_FAIL " + $_.Exception.Message }
}

# ---------- 起假魔兽 ----------
$env:FAKE_UNITS = '60'
$env:FAKE_HEAP_MB = '0'
$env:FAKE_IMMORTAL = '0'
$env:FAKE_AMP = '150'
$fgOut = Join-Path $fg "stress_fake_out.log"
$fgErr = Join-Path $fg "stress_fake_err.log"
Remove-Item $fgOut, $fgErr -ErrorAction SilentlyContinue
$fake = Start-Process -FilePath (Join-Path $fg "fakewar3.exe") -ArgumentList "180" -WorkingDirectory $fg `
    -RedirectStandardOutput $fgOut -RedirectStandardError $fgErr -PassThru -WindowStyle Hidden
Write-Host "FAKE PID=$($fake.Id)"
Start-Sleep -Seconds 2

# ---------- 起 GUI（--pid 精确连到刚起的假魔兽）----------
$guiOut = Join-Path $bin "stress_gui_out.log"
$guiErr = Join-Path $bin "stress_gui_err.log"
Remove-Item $guiOut, $guiErr -ErrorAction SilentlyContinue
$beforeLogs = Get-DssLogs
$gui = Start-Process -FilePath (Join-Path $bin "War3DeathSettlement.exe") `
    -ArgumentList "--pid", "$($fake.Id)", "--force-version", "1.27.0.52240" -WorkingDirectory $bin `
    -RedirectStandardOutput $guiOut -RedirectStandardError $guiErr -PassThru -WindowStyle Normal
Write-Host "GUI PID=$($gui.Id)"
$guiStart = Get-Date

# ---------- 等窗口出现 ----------
$deadline = (Get-Date).AddSeconds(25)
$hwnd = 0
while ((Get-Date) -lt $deadline) {
    $p = Get-Process -Id $gui.Id -ErrorAction SilentlyContinue
    if (-not $p) { Write-Host "GUI_EXITED_EARLY"; break }
    try { $hwnd = $p.MainWindowHandle } catch { $hwnd = 0 }
    if ($hwnd -ne 0) { break }
    Start-Sleep -Milliseconds 300
}
Write-Host "WINDOW hwnd=$hwnd"

# 等连接 + 事件积累
Start-Sleep -Seconds 10

$uiaCondCombo = New-Object System.Windows.Automation.PropertyCondition($uia::ControlTypeProperty, [System.Windows.Automation.ControlType]::ComboBox)
$uiaCondTab   = New-Object System.Windows.Automation.PropertyCondition($uia::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)
$uiaCondRow   = New-Object System.Windows.Automation.PropertyCondition($uia::ControlTypeProperty, [System.Windows.Automation.ControlType]::DataItem)

$switchCount = 0
$rowClicks = 0
$tabSwitches = 0
$duration = 30

$deadline = (Get-Date).AddSeconds($duration)
$iteration = 0
while ((Get-Date) -lt $deadline) {
    $iteration++
    $we = Find-MainWindowElement $gui.Id

    if ($we) {
        $combos = $we.FindAll([System.Windows.Automation.TreeScope]::Descendants, $uiaCondCombo)
        if ($combos.Count -ge 2) {
            for ($k = 0; $k -lt 2; $k++) {
                $alt = $iteration % 2
                $target = if ($alt -eq 1) { 1 } else { 0 }
                if (Select-ComboItem $combos[$k] $target) { $switchCount++ }
            }
        }

        if ($iteration % 5 -eq 0) {
            # 点表格行：WinForms DataGridView 的行在 UIA 里是 DataItem
            try {
                $rows = $we.FindAll([System.Windows.Automation.TreeScope]::Descendants, $uiaCondRow)
                if ($rows.Count -gt 0) {
                    $rows[($iteration % $rows.Count)].GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
                    $rowClicks++
                }
            } catch { }

            try {
                $tabs = $we.FindAll([System.Windows.Automation.TreeScope]::Descendants, $uiaCondTab)
                if ($tabs.Count -ge 3) {
                    $tabs[(($iteration / 5) % 3)].GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
                    $tabSwitches++
                }
            } catch { }
        }
    }

    if (-not (Get-Process -Id $gui.Id -ErrorAction SilentlyContinue)) { Write-Host "GUI_DIED at iteration $iteration"; break }
    Start-Sleep -Milliseconds 400
}

$survivedSec = [math]::Round(((Get-Date) - $guiStart).TotalSeconds, 1)
$alive = [bool](Get-Process -Id $gui.Id -ErrorAction SilentlyContinue)
Write-Host "RESULT iterations=$iteration switchCount=$switchCount rowClicks=$rowClicks tabSwitches=$tabSwitches survivedSec=$survivedSec alive=$alive"

# ---------- 切到「伤害事件」页并截图 ----------
Start-Sleep -Seconds 1
$we = Find-MainWindowElement $gui.Id
if ($we) {
    try {
        $tabs = $we.FindAll([System.Windows.Automation.TreeScope]::Descendants, $uiaCondTab)
        foreach ($t in $tabs) {
            if ($t.Current.Name -match '伤害事件') {
                $t.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
                break
            }
        }
    } catch { }
}
Start-Sleep -Seconds 1
$shotPath = Join-Path $test "stress_reentry_hook_tab.png"
Shot $gui.Id $shotPath

# ---------- 日志异常扫描（只扫本次 GUI 的日志，不把旧日志的历史命中算进来）----------
$exceptions = 0
$exLines = @()
$afterLogs = Get-DssLogs
$newLogs = @($afterLogs | Where-Object { $_.LastWriteTime -ge $guiStart })
if ($newLogs.Count -eq 0) { $newLogs = @($afterLogs | Select-Object -First 1) }
Write-Host "SCANNED_LOGS=" + (($newLogs | ForEach-Object Name) -join ',')
foreach ($log in $newLogs) {
    try {
        $txt = Get-Content $log.FullName -Raw -Encoding UTF8
        $hits = [regex]::Matches($txt, 'InvalidOperationException|Collection was modified')
        if ($hits.Count -gt 0) { $exceptions += $hits.Count; $exLines += "$($log.Name): $($hits.Count) hit(s)" }
    } catch { }
}
Write-Host "EXCEPTION_COUNT=$exceptions"
foreach ($l in $exLines) { Write-Host "EXHIT $l" }

# 清理：只杀本次起的进程
Stop-Process -Id $gui.Id -Force -ErrorAction SilentlyContinue
Stop-Process -Id $fake.Id -Force -ErrorAction SilentlyContinue
Write-Host "DONE"
