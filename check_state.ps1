# check_state.ps1 -- one command to answer "what config is this game actually running?"
#   * game process + start time
#   * whether the 4 locations (snapshot + YDWE + WFE) agree for ini and DLL
#   * which chat_marker / chat_diag / pick the LAST game start actually read
#     (if a game start read the old config, this shows it immediately)
#
# NOTE: ASCII-only on purpose -- Windows PowerShell 5.1 reads BOM-less .ps1 as
#       ANSI/GBK and mangles non-ASCII literals (that already broke this file once).
#
# Usage:  .\check_state.ps1
[CmdletBinding()]
param()

$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$gbk  = [System.Text.Encoding]::GetEncoding(936)

function Get-Hash16($p) { if (Test-Path $p) { (Get-FileHash $p -Algorithm SHA256).Hash.Substring(0,16) } else { 'MISSING' } }

Write-Host ''
Write-Host '== game process ==' -ForegroundColor Cyan
$procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '(?i)^war3|^wfe' }
if ($procs) {
	foreach ($p in $procs) {
		$st = ''
		try { $st = (Get-CimInstance Win32_Process -Filter ("ProcessId=" + $p.Id) -ErrorAction Stop).CreationDate } catch { }
		Write-Host ("   PID {0,-8} {1}   started {2}" -f $p.Id, $p.ProcessName, $st)
	}
} else { Write-Host '   not running' }

Write-Host ''
Write-Host '== file consistency ==' -ForegroundColor Cyan
$snapIni = Join-Path $root '_config\UDamageWatcher.ini.working'
$artDll  = Join-Path $root '_build\watcher\UDamageWatcher.dll'
$iniT    = @((Join-Path $root 'warcraft3\UDamageWatcher.ini'),
             'C:\3rd\wc3gamesearcher\WFE\Application\Libraries\UDamageWatcher.ini')
$dllT    = @((Join-Path $root 'warcraft3\UDamageWatcher.dll'),
             'C:\3rd\wc3gamesearcher\WFE\Application\Libraries\UDamageWatcher.dll')

$hi = Get-Hash16 $snapIni
$hd = Get-Hash16 $artDll
Write-Host ("   ini source {0}" -f $hi)
foreach ($t in $iniT) {
	$h = Get-Hash16 $t
	$ok = ($h -eq $hi)
	$c = 'Red'; if ($ok) { $c = 'Green' }
	Write-Host ("   ini {0}  {1}" -f $h, (Split-Path $t -Parent)) -ForegroundColor $c
}
Write-Host ("   dll build  {0}" -f $hd)
foreach ($t in $dllT) {
	$h = Get-Hash16 $t
	$ok = ($h -eq $hd)
	$c = 'Red'; if ($ok) { $c = 'Green' }
	Write-Host ("   dll {0}  {1}" -f $h, (Split-Path $t -Parent)) -ForegroundColor $c
}

Write-Host ''
Write-Host '== last game start: config it actually read ==' -ForegroundColor Cyan
$log = 'C:\3rd\wc3gamesearcher\WFE\Application\Libraries\UDamageWatcher.log'
if (-not (Test-Path $log)) { Write-Host '   no log'; return }
$lines = $gbk.GetString([System.IO.File]::ReadAllBytes($log)) -split "`r`n|`n"

$banner = ($lines | Select-String -Pattern 'UDamageWatcherHook v' | Select-Object -Last 1).Line
$cfg    = ($lines | Select-String -Pattern 'enable=1 log_only' | Select-Object -Last 1).Line
if ($banner) { Write-Host ("   {0}" -f $banner) }
if ($cfg) {
	foreach ($k in @('chat_marker', 'chat_diag', 'chat_dr', 'backend', 'chat_on_death')) {
		$m = [regex]::Match($cfg, [regex]::Escape($k) + '=("?)([^"\s|]*)')
		if ($m.Success) { Write-Host ("   {0,-16} = {1}" -f $k, $m.Groups[2].Value) }
	}
	$m = [regex]::Match($cfg, 'pick=(\d+)')
	if ($m.Success) { Write-Host ("   pick             = {0}" -f $m.Groups[1].Value) }
}
Write-Host ''
Write-Host ("   log last write: {0}" -f (Get-Item $log).LastWriteTime)
