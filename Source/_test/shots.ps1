# shots.ps1 -- fake-war3 GUI screenshots for the new columns/pagination/popup.
# ASCII-only on purpose; Chinese tab/button names are built from [char] codes.
param(
    [Parameter(Mandatory=$true)][ValidateSet('small','big')][string]$Mode
)
$ErrorActionPreference = 'Stop'

$test = $PSScriptRoot
$root = Split-Path -Parent $test          # DeathSettlement
$fg   = Join-Path $test "fakegame"
$bin  = Join-Path $root "bin\Release\net10.0-windows"
$outdir = Join-Path $test "shots"
New-Item -ItemType Directory -Force -Path $outdir | Out-Null

# Chinese labels
$TAB_HOOK   = -join (0x4F24,0x5BB3,0x4E8B,0x4EF6 | ForEach-Object { [char]$_ })   # 伤害事件
$TAB_SETTLE = -join (0x6B7B,0x4EA1,0x7ED3,0x7B97 | ForEach-Object { [char]$_ })   # 死亡结算
$BTN_NEXT   = -join (0x4E0B,0x4E00,0x9875 | ForEach-Object { [char]$_ })           # 下一页

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
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint data, IntPtr extra);
  [DllImport("user32.dll")] public static extern int GetWindowTextW(IntPtr hWnd, System.Text.StringBuilder sb, int max);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint flags);
  public delegate bool EnumProc(IntPtr hWnd, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);

  public const uint LEFTDOWN=0x02, LEFTUP=0x04;
  public const int SWP_NOSIZE=0x0001, SWP_NOMOVE=0x0002, SWP_SHOWWINDOW=0x0040;
  public static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
  public static readonly IntPtr HWND_NOTOPMOST = new IntPtr(-2);

  public static string Title(IntPtr h) {
    var sb = new System.Text.StringBuilder(512);
    GetWindowTextW(h, sb, sb.Capacity);
    return sb.ToString();
  }

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

  public static IntPtr FindByTitleSubstring(int targetPid, string sub) {
    IntPtr found = IntPtr.Zero;
    EnumWindows(delegate(IntPtr h, IntPtr l) {
      uint pid; GetWindowThreadProcessId(h, out pid);
      if (pid != targetPid) return true;
      if (!IsWindowVisible(h)) return true;
      if (Title(h).Contains(sub)) { found = h; return false; }
      return true;
    }, IntPtr.Zero);
    return found;
  }

  public static void DblClick(int x, int y) {
    SetCursorPos(x, y);
    System.Threading.Thread.Sleep(80);
    mouse_event(LEFTDOWN,0,0,0,IntPtr.Zero); mouse_event(LEFTUP,0,0,0,IntPtr.Zero);
    System.Threading.Thread.Sleep(90);
    mouse_event(LEFTDOWN,0,0,0,IntPtr.Zero); mouse_event(LEFTUP,0,0,0,IntPtr.Zero);
  }
  public static void Click(int x, int y) {
    SetCursorPos(x, y);
    System.Threading.Thread.Sleep(80);
    mouse_event(LEFTDOWN,0,0,0,IntPtr.Zero); mouse_event(LEFTUP,0,0,0,IntPtr.Zero);
  }
}
"@

function Shot-Pid([int]$ProcId, [string]$Out) {
    $hwnd = [W32Shot]::FindMain($ProcId)
    if ($hwnd -eq [IntPtr]::Zero) { throw "PID $ProcId has no top-level window" }
    Shot-Window $hwnd $Out
}

function Shot-Window([IntPtr]$hwnd, [string]$Out) {
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

function Start-Fake([string]$units, [string]$seconds) {
    $env:FAKE_UNITS=$units; $env:FAKE_HEAP_MB=0; $env:FAKE_IMMORTAL=0; $env:FAKE_AMP=150
    $fo = Join-Path $fg "shots_fake_out.log"; $fe = Join-Path $fg "shots_fake_err.log"
    Remove-Item $fo,$fe -ErrorAction SilentlyContinue
    $p = Start-Process -FilePath (Join-Path $fg "fakewar3.exe") -ArgumentList $seconds -WorkingDirectory $fg `
        -RedirectStandardOutput $fo -RedirectStandardError $fe -PassThru -WindowStyle Hidden
    Write-Host "FAKE PID=$($p.Id)"
    return $p.Id
}

function Start-Gui([string]$suffix) {
    $go = Join-Path $bin "shots_${suffix}_gui_out.log"; $ge = Join-Path $bin "shots_${suffix}_gui_err.log"
    Remove-Item $go,$ge -ErrorAction SilentlyContinue
    $p = Start-Process -FilePath (Join-Path $bin "War3DeathSettlement.exe") `
        -ArgumentList "--name","fakewar3","--force-version","1.27.0.52240" -WorkingDirectory $bin `
        -RedirectStandardOutput $go -RedirectStandardError $ge -PassThru -WindowStyle Normal
    Write-Host "GUI PID=$($p.Id)"
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

$rootEl = [System.Windows.Automation.AutomationElement]::RootElement

function Get-WinEl([int]$ProcId) {
    $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, $ProcId)
    $win = $rootEl.FindFirst([System.Windows.Automation.TreeScope]::Children, $cond)
    if (-not $win) { throw "no automation window for pid $ProcId" }
    return $win
}

function Select-Tab([System.Windows.Automation.AutomationElement]$win, [string]$name) {
    $cond = New-Object System.Windows.Automation.AndCondition(
        (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)),
        (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $name)))
    $tab = $win.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
    if (-not $tab) { throw "tab not found: $name" }
    $sel = $tab.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern)
    $sel.Select()
    Start-Sleep -Milliseconds 500
    Write-Host "TAB selected: $name"
}

function Get-GridRects([System.Windows.Automation.AutomationElement]$win) {
    $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::DataGrid)
    $all = $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
    $list = @()
    for ($i = 0; $i -lt $all.Count; $i++) {
        $r = $all.Item($i).Current.BoundingRectangle
        $list += [pscustomobject]@{ Left=[int]$r.Left; Top=[int]$r.Top; Right=[int]$r.Right; Bottom=[int]$r.Bottom }
    }
    return $list
}

function DblClickFirstDataRow([System.Windows.Automation.AutomationElement]$win, [int]$gid) {
    $grids = Get-GridRects $win
    if ($grids.Count -eq 0) { throw "no grids found" }
    $g = $grids | Sort-Object Top | Select-Object -First 1
    $x = [int]($g.Left + 60)
    $y = [int]($g.Top + 26 + 11)   # column header 26 + half a row (22px rows)
    $main = [W32Shot]::FindMain($gid)
    # bring the main window above any console window so the synthesized click lands on it
    [W32Shot]::SetWindowPos($main, [W32Shot]::HWND_TOPMOST, 0, 0, 0, 0, [W32Shot]::SWP_NOMOVE -bor [W32Shot]::SWP_NOSIZE -bor [W32Shot]::SWP_SHOWWINDOW) | Out-Null
    Start-Sleep -Milliseconds 400
    [W32Shot]::SetForegroundWindow($main) | Out-Null
    Start-Sleep -Milliseconds 300
    Write-Host "DBLCLICK grid top=$($g.Top) at ($x,$y)"
    [W32Shot]::DblClick($x, $y)
    Start-Sleep -Milliseconds 200
    [W32Shot]::SetWindowPos($main, [W32Shot]::HWND_NOTOPMOST, 0, 0, 0, 0, [W32Shot]::SWP_NOMOVE -bor [W32Shot]::SWP_NOSIZE -bor [W32Shot]::SWP_SHOWWINDOW) | Out-Null
}

switch ($Mode) {
  'small' {
    $fid = Start-Fake "30" "90"
    Start-Sleep -Seconds 2
    $gid = Start-Gui "small"
    Wait-GuiWindow $gid 20
    Start-Sleep -Seconds 20

    # screenshot 1: death settlement page (default tab)
    Shot-Pid $gid (Join-Path $outdir "shot1_settlement.png")

    $win = Get-WinEl $gid
    Select-Tab $win $TAB_HOOK
    Start-Sleep -Seconds 2
    Shot-Pid $gid (Join-Path $outdir "shot2_hook.png")

    Select-Tab $win $TAB_SETTLE
    Start-Sleep -Seconds 2
    DblClickFirstDataRow $win $gid
    Start-Sleep -Seconds 2
    # screenshot the popup window itself (its title is "单位名 0x地址", contains "0x")
    $pop = [W32Shot]::FindByTitleSubstring($gid, "0x")
    if ($pop -ne [IntPtr]::Zero) {
        Write-Host "POPUP title: $([W32Shot]::Title($pop))"
        Shot-Window $pop (Join-Path $outdir "shot3_popup.png")
    } else {
        Write-Host "POPUP window not found; falling back to main window"
        Shot-Pid $gid (Join-Path $outdir "shot3_popup.png")
    }

    Stop-Process -Id $gid -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $fid -Force -ErrorAction SilentlyContinue
    Write-Host "SMALL DONE"
  }
  'big' {
    $fid = Start-Fake "80" "320"
    Start-Sleep -Seconds 2
    $gid = Start-Gui "big"
    Wait-GuiWindow $gid 20
    Write-Host "accumulating events for 260s..."
    Start-Sleep -Seconds 260

    $win = Get-WinEl $gid
    Select-Tab $win $TAB_HOOK
    Start-Sleep -Seconds 2
    Shot-Pid $gid (Join-Path $outdir "shot4_hook_page1.png")

    # click 下一页 (next page) button via UIAutomation if possible
    $cond = New-Object System.Windows.Automation.AndCondition(
        (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)),
        (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $BTN_NEXT)))
    $btn = $win.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
    if ($btn) {
        $inv = $btn.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
        $inv.Invoke()
        Write-Host "CLICKED next page"
    } else {
        Write-Host "next button not found via UIA; will screenshot page 1 only"
    }
    Start-Sleep -Seconds 2
    Shot-Pid $gid (Join-Path $outdir "shot4_hook_page2.png")

    Stop-Process -Id $gid -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $fid -Force -ErrorAction SilentlyContinue
    Write-Host "BIG DONE"
  }
}

Remove-Item Env:FAKE_UNITS,Env:FAKE_HEAP_MB,Env:FAKE_IMMORTAL,Env:FAKE_AMP -ErrorAction SilentlyContinue
