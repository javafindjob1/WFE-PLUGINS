<#
================================================================================
 deploy_watcher.ps1 -- install the freshly built UDamageWatcher into WFE Libraries
================================================================================
 Why this exists (2026-10-02):
   build_watcher.ps1 can no longer be used as the deploy path: its step 5 runs the
   selftest and reads the child process exit code, which is unreadable on this
   machine (cl.exe/selftest exit with an EMPTY code), so it Dies before reaching
   step 7 -- the WFE copy. build2.ps1 works around the compile half; this script
   does the install half deterministically.

 What it does (idempotent; each step verified by SHA256, never by exit code):
   1. copies _build\watcher\UDamageWatcher.dll -> <WFE>\Application\Libraries\UDamageWatcher.dll
      (the LIVE loader: WFE auto-injects the plugin)
   2. copies the working ini next to it, so the deployed config is the
      verified snapshot (backend=2 native, encoding=2 UTF-8, pick=auto)
   3. re-reads the files and fails loudly on any hash mismatch

 Usage:
   .\deploy_watcher.ps1
   .\deploy_watcher.ps1 -Wfe 'D:\...\WFE\Application\Libraries'
================================================================================
#>
[CmdletBinding()]
param(
	[string]$Wfe = '',
	[string]$CommitMsg = ''
)

$ErrorActionPreference = 'Stop'

function Info($m) { Write-Host $m }
function Ok($m)   { Write-Host $m -ForegroundColor Green }
function Warn($m) { Write-Host $m -ForegroundColor Yellow }
function Die($m)  { Write-Host $m -ForegroundColor Red; exit 1 }
function Step($m) { Write-Host ''; Write-Host "== $m ==" -ForegroundColor Cyan }

$root     = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$buildDir = Join-Path $root '_build\watcher'
$artDll   = Join-Path $buildDir 'UDamageWatcher.dll'
$artIni   = Join-Path $buildDir 'UDamageWatcher.ini'

Step '0/4 locate inputs'

if (-not (Test-Path $artDll)) { Die "artifact missing: $artDll (run _tools\build2.ps1 first)" }
$artHash = (Get-FileHash $artDll -Algorithm SHA256).Hash
Ok ("artifact : {0}  {1:N0} bytes  SHA256={2}" -f $artDll, (Get-Item $artDll).Length, $artHash.Substring(0, 16))

# ini source: the verified working snapshot (backend=2 native, encoding=2 UTF-8).
$iniCandidates = @(
	(Join-Path $root '_config\UDamageWatcher.ini.working')
)
$iniSrc = $iniCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
$iniHash = ''
if (-not $iniSrc) { Warn 'no ini source found; ini will not be deployed' }
else {
	$iniHash = (Get-FileHash $iniSrc -Algorithm SHA256).Hash
	Ok ("ini src  : {0}  SHA256={1}" -f $iniSrc, $iniHash.Substring(0, 16))
}

# WFE Libraries folder
if (-not $Wfe) {
	foreach ($g in @('C:\3rd\wc3gamesearcher\WFE\Application\Libraries',
	                 'D:\fsdownload\wc3gamesearcher\WFE\Application\Libraries')) {
		if (Test-Path $g) { $Wfe = $g; break }
	}
}
if ($Wfe -and (Test-Path $Wfe)) { Ok ("WFE libs : {0}" -f $Wfe) }
else { Die 'WFE Libraries folder not found; nothing to deploy (pass -Wfe)' }

#------------------------------------------------------------------------------
$targets = @()
if ($Wfe) { $targets += [pscustomobject]@{ Name = 'WFE Libraries'; Dir = $Wfe } }

Step '1/4 copy ini FIRST, then DLL (ini is never locked; a locked DLL must not skip it)'
$bad = 0
foreach ($t in $targets) {
	if (-not (Test-Path $t.Dir)) { Warn ("skip {0}: {1} does not exist" -f $t.Name, $t.Dir); continue }

	# --- ini first ---------------------------------------------------------
	# 2026-10-02 bug: this script used to copy the DLL first and then Die() when
	# the DLL was locked by a running game -- so the ini was never copied and the
	# next game start silently used the OLD config (chat_marker stayed "<标记>").
	# The ini cannot be locked by anything, so it always goes first now.
	if ($iniSrc) {
		$ini = Join-Path $t.Dir 'UDamageWatcher.ini'
		Copy-Item $iniSrc $ini -Force
		$same = $false
		try {
			$same = ((Get-FileHash $ini -Algorithm SHA256).Hash -eq $iniHash)
		} catch { }
		if ($same) { Ok ("{0,-16} ini   {1}  (verified)" -f $t.Name, $ini) }
		else       { Die ("ini copy did NOT take effect: {0}" -f $ini) }
	}

	# --- then the DLL ------------------------------------------------------
	# 2026-10-02/3: DO NOT rename a mapped DLL aside and hope the next launch
	# picks up the new one. Measured: it does not reliably work -- two game
	# processes started at 23:51 still had the pre-23:45 build loaded (the call
	# chain literally printed the module name "UDamageWatcher.locked-*.dll",
	# which is the renamed old file). A stale plugin means the version banner in
	# the log lies about which code is running, which is exactly the kind of
	# false signal that wasted a whole reverse-engineering round.
	# So: if the DLL is locked, FAIL. The watcher deploys the moment the game
	# closes, so this is never actually a problem in practice.
	$dll = Join-Path $t.Dir 'UDamageWatcher.dll'
	try {
		Copy-Item $artDll $dll -Force
		Ok ("{0,-16} dll   {1}" -f $t.Name, $dll)
	} catch {
		Warn ("{0,-16} dll   LOCKED (game running?) -- {1}" -f $t.Name, $_.Exception.Message)
		Warn '  -> refusing to rename it aside: a stale module makes the version'
		Warn '     banner lie. Close the game; the watcher deploys automatically.'
		$bad++
	}
}

#------------------------------------------------------------------------------
Step '2/4 verify SHA256 of every deployed DLL'
$verifyBad = 0
foreach ($t in $targets) {
	$dll = Join-Path $t.Dir 'UDamageWatcher.dll'
	if (-not (Test-Path $dll)) { Warn ("missing: {0}" -f $dll); $verifyBad++; continue }
	$h = (Get-FileHash $dll -Algorithm SHA256).Hash
	$match = ($h -eq $artHash)
	if (-not $match) { $verifyBad++ }
	$verdict = 'MISMATCH'
	$color = 'Red'
	if ($match) { $verdict = 'MATCH'; $color = 'Green' }
	Write-Host ("  {0,-16} {1,8:N0} bytes  {2}  {3}" -f `
		$t.Name, (Get-Item $dll).Length, $h.Substring(0, 16), $verdict) -ForegroundColor $color
}
$bad += $verifyBad
if ($bad -gt 0) { Die ("$bad deployed file(s) need attention (see warnings above)") }

#------------------------------------------------------------------------------
# 2b/4: prove WHICH source revision the artifact came from, and clean up the
# renamed-aside copies left by the old (broken) rename-based deploy. Those are
# plain DLLs sitting in the plugin folder; if the game ever picks one up the
# version banner lies about the running code.
Step '2b/4 artifact provenance + stale-copy cleanup'
$srcFile = Join-Path $root 'UDamageWatcherHook.cpp'
if (Test-Path $srcFile) {
	$line = (Select-String -Path $srcFile -Pattern 'UDamageWatcherHook v[0-9.]+' | Select-Object -First 1).Line
	if ($line) {
		$ver = [regex]::Match($line, 'v[0-9]+\.[0-9]+\.[0-9]+').Value
		# the version banner is a UTF-8 string literal in the source; the compiler
		# copies it into the binary verbatim, so we can prove the artifact matches
		$bytes = [System.IO.File]::ReadAllBytes($artDll)
		$needle = [System.Text.Encoding]::UTF8.GetBytes("UDamageWatcherHook $ver")
		$found = $false
		for ($i = 0; $i -le $bytes.Length - $needle.Length; $i++) {
			if ($bytes[$i] -eq $needle[0]) {
				$ok = $true
				for ($j = 1; $j -lt $needle.Length; $j++) { if ($bytes[$i + $j] -ne $needle[$j]) { $ok = $false; break } }
				if ($ok) { $found = $true; break }
			}
		}
		if ($found) { Ok ("  artifact self-identifies as {0}  (banner string present)" -f $ver) }
		else {
			Warn ("  !! source says {0} but the artifact has no such banner -> STALE ARTIFACT" -f $ver)
			Warn '     run _tools\build2.ps1 before deploying'
			Die  '  refusing to deploy an artifact that does not match the source'
		}
	}
}
$stale = 0
foreach ($t in $targets) {
	foreach ($f in @(Get-ChildItem $t.Dir -Filter 'UDamageWatcher.locked-*.dll' -ErrorAction SilentlyContinue)) {
		Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
		if (Test-Path $f.FullName) { Warn ("  could not remove stale copy: {0}" -f $f.FullName) }
		else { Ok ("  removed stale copy {0} ({1:N0} bytes)" -f $f.Name, $f.Length); $stale++ }
	}
}
if ($stale -eq 0) { Info '  no stale renamed-aside copies present' }

#------------------------------------------------------------------------------
# 3/4：git 本地提交 —— 每次部署留一个可回滚的提交点（防止改错难回滚）
#   提交的是【源码 + 配置快照 + 脚本】，不是 _build 产物（.gitignore 已排除）。
#   想自定义提交信息就加 -CommitMsg 'xxx'；默认带时间戳。
#------------------------------------------------------------------------------
Step '3/4 git commit (local rollback point)'
$gitExe = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitExe) {
    Warn '  git 不可用，跳过提交'
} else {
    $dirty = & git -C $root status --porcelain 2>$null
    if ($dirty) {
        $msg = if ($CommitMsg) { $CommitMsg } else { "部署提交 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" }
        & git -C $root add -A
        & git -C $root commit -m $msg
        if ($LASTEXITCODE -eq 0) { Ok '  git 本地提交完成' }
        else { Warn '  git commit 返回非 0，提交可能失败（不影响部署）' }
    } else {
        Info '  工作区干净，没有可提交的改动'
    }
}

#------------------------------------------------------------------------------
Step '4/4 done'
Ok '================================================================'
Ok ' deploy complete -- restart the game for it to take effect'
Ok '================================================================'
Info ("  build artifact : {0}" -f $artDll)
foreach ($t in $targets) { Info ("  {0,-16}: {1}" -f $t.Name, (Join-Path $t.Dir 'UDamageWatcher.dll')) }
Info ''
Info '  test: launch the game, select one of your own units, press Ctrl+Alt+R'
