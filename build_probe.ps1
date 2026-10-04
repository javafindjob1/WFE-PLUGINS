<#
================================================================================
 build_probe.ps1 —— 构建 / 自检 / 安装 UDamageProbe 探针插件
================================================================================
 流程：
   1. 找 vcvarsall.bat（x86 交叉编译，魔兽是 32 位程序）
   2. 编译 UDamageProbe.cpp -> _build\probe\UDamageProbe.dll
   3. 编译 UDamageProbeSmoke.cpp -> _build\probe\UDamageProbeSmoke.exe
   4. dumpbin /exports 校验导出 Initialize / PluginName
   5. 跑自检：在假目录里 LoadLibrary + Initialize，验证
      "没有 JAPI/ydbase 时安全降级、日志写出、进程不崩"
   6. 复制 DLL 到 warcraft3\UDamageProbe.dll
   7. 在 warcraft3\config.cfg（GBK）里补一行 "UDamageProbe.dll = 1"
      （先备份 config.cfg.probe.bak，幂等，不动其它行）
   8. 打印安装结果与测试步骤

 用法：
   .\build_probe.ps1
   .\build_probe.ps1 -Verbose            # 编译时打开 PROBE_VERBOSE（dump 原始 dword）
   .\build_probe.ps1 -SkipInstall        # 只编译 + 自检，不安装
   .\build_probe.ps1 -VcVars "D:\...\vcvarsall.bat"

 注意：本脚本绝不写 D:\war5。日志与产物只落在 plugin 目录内。
================================================================================
#>
[CmdletBinding()]
param(
	[string]$VcVars     = '',
	[switch]$SkipInstall,
	[switch]$ProbeVerbose
)

$ErrorActionPreference = 'Stop'

function Info($m) { Write-Host $m }
function Ok($m)   { Write-Host $m -ForegroundColor Green }
function Warn($m) { Write-Host $m -ForegroundColor Yellow }
function Die($m)  { Write-Host $m -ForegroundColor Red; exit 1 }
function Step($m) { Write-Host ''; Write-Host "== $m ==" -ForegroundColor Cyan }

# cbScriptRoot = 本脚本所在目录（即 <WS>）
$root      = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$pluginDir = Join-Path $root 'warcraft3'
$buildDir  = Join-Path $root '_build\probe'
$dllOut    = Join-Path $buildDir 'UDamageProbe.dll'
$smokeExe  = Join-Path $buildDir 'UDamageProbeSmoke.exe'
$logDir    = Join-Path $root '_selftest\probe'

Info "工作区 : $root"
Info "插件目录: $pluginDir"
Info "构建目录: $buildDir"

#------------------------------------------------------------------------------
# 1. 找 vcvarsall.bat
#------------------------------------------------------------------------------
Step '1/8 定位 MSVC (vcvarsall.bat x86)'

function Find-VcVars {
	param([string]$Explicit)
	if ($Explicit) {
		if (Test-Path $Explicit) { return $Explicit }
		Die "指定的 -VcVars 不存在: $Explicit"
	}
	$bases = @(
		'D:\Program Files\Microsoft Visual Studio',
		'C:\Program Files\Microsoft Visual Studio',
		'D:\Program Files (x86)\Microsoft Visual Studio',
		'C:\Program Files (x86)\Microsoft Visual Studio'
	)
	$found = @()
	foreach ($b in $bases) {
		if (-not (Test-Path $b)) { continue }
		$found += Get-ChildItem -Path $b -Recurse -Depth 6 -Filter 'vcvarsall.bat' -File -ErrorAction SilentlyContinue |
			Where-Object { $_.FullName -like '*\VC\Auxiliary\Build\vcvarsall.bat' } |
			Select-Object -ExpandProperty FullName
	}
	# 优先 VS18 / Insiders，其次版本号从高到低
	$found = $found | Sort-Object -Unique
	$pref = $found | Where-Object { $_ -like '*\18\*' } | Select-Object -First 1
	if ($pref) { return $pref }
	if ($found.Count -gt 0) { return $found[0] }
	Die ' 找不到 vcvarsall.bat，请用 -VcVars 指定'
}

$vcvars = Find-VcVars -Explicit $VcVars
Ok "vcvarsall: $vcvars"

# 统一用它跑命令行（vcvarsall 只影响当前 cmd 会话）
function Invoke-Vc {
	param([string]$Cmd, [string]$WorkDir)
	$full = "call `"$vcvars`" x86 >nul 2>&1 && $Cmd"
	$old = Get-Location
	if ($WorkDir) { Set-Location $WorkDir }
	try {
		$out = cmd /c $full 2>&1
		$code = $LASTEXITCODE
	} finally {
		Set-Location $old
	}
	return [pscustomobject]@{ Output = ($out | Out-String); Code = $code }
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

#------------------------------------------------------------------------------
# 2. 编译探针 DLL
#------------------------------------------------------------------------------
Step '2/8 编译 UDamageProbe.dll'

$srcProbe = Join-Path $root 'UDamageProbe.cpp'
if (-not (Test-Path $srcProbe)) { Die "找不到源码: $srcProbe" }

$verboseDef = if ($ProbeVerbose) { '/DPROBE_VERBOSE=1' } else { '' }
$clDll = "cl /nologo /utf-8 /LD /O2 /MT /EHsc /W3 $verboseDef " +
         "/Fe:`"$dllOut`" /Fo:`"$buildDir\UDamageProbe.obj`" `"$srcProbe`" " +
         "/link /SUBSYSTEM:WINDOWS"

$r = Invoke-Vc -Cmd $clDll -WorkDir $buildDir
Write-Host $r.Output
if ($r.Code -ne 0) { Die "编译 UDamageProbe.dll 失败 (exit $($r.Code))" }
if (-not (Test-Path $dllOut)) { Die "编译声称成功但没有产物: $dllOut" }
Ok ("DLL 编译成功: {0} ({1:N0} 字节)" -f $dllOut, (Get-Item $dllOut).Length)
if ($ProbeVerbose) { Warn 'PROBE_VERBOSE 已打开：日志会额外 dump 原始 dword' }

#------------------------------------------------------------------------------
# 3. 编译自检程序
#------------------------------------------------------------------------------
Step '3/8 编译自检程序 UDamageProbeSmoke.exe'

$srcSmoke = Join-Path $root 'UDamageProbeSmoke.cpp'
if (-not (Test-Path $srcSmoke)) { Die "找不到源码: $srcSmoke" }

$clSmoke = "cl /nologo /utf-8 /O2 /MT /EHsc /W3 " +
           "/Fe:`"$smokeExe`" /Fo:`"$buildDir\UDamageProbeSmoke.obj`" `"$srcSmoke`""

$r = Invoke-Vc -Cmd $clSmoke -WorkDir $buildDir
Write-Host $r.Output
if ($r.Code -ne 0) { Die "编译自检程序失败 (exit $($r.Code))" }
Ok ("自检程序编译成功: {0} ({1:N0} 字节)" -f $smokeExe, (Get-Item $smokeExe).Length)

#------------------------------------------------------------------------------
# 4. dumpbin /exports 校验导出
#------------------------------------------------------------------------------
Step '4/8 dumpbin /exports 校验导出 Initialize / PluginName'

$r = Invoke-Vc -Cmd "dumpbin /nologo /exports `"$dllOut`"" -WorkDir $buildDir
$exports = $r.Output
$hasInit = ($exports -match '(?m)^\s+\d+\s+[0-9A-F]+\s+[0-9A-F]{8}\s+Initialize\s*$')
$hasName = ($exports -match '(?m)^\s+\d+\s+[0-9A-F]+\s+[0-9A-F]{8}\s+PluginName\s*$')
$exports.Trim() -split "`r?`n" | Where-Object { $_ -match '\S' } | Select-Object -Last 12 | ForEach-Object { Write-Host "   $_" }
if (-not $hasInit) { Die 'dumpbin 未看到 Initialize 导出' }
if (-not $hasName) { Die 'dumpbin 未看到 PluginName 导出' }
Ok '导出校验通过: Initialize + PluginName'

# 顺便确认这是 32 位 DLL
$r = Invoke-Vc -Cmd "dumpbin /nologo /headers `"$dllOut`"" -WorkDir $buildDir
$hdr = $r.Output
if ($hdr -match '14C machine \(x86\)') {
	Ok '目标架构: x86 (machine 14C) —— 与 32 位魔兽一致'
} elseif ($hdr -match '8664 machine \(x64\)') {
	Die '产物是 x64，魔兽无法加载！检查 vcvarsall 是否用了 x86 参数'
} else {
	Warn '未能确认目标架构，请人工核对 dumpbin /headers'
}

#------------------------------------------------------------------------------
# 5. 跑自检（假目录，不碰 D:\war5）
#------------------------------------------------------------------------------
Step '5/8 运行本机自检（无 JAPI/ydbase 环境，验证安全降级）'

Remove-Item $logDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$smokeOut = & $smokeExe $dllOut $logDir 2>&1
$smokeCode = $LASTEXITCODE
$smokeOut | ForEach-Object { Write-Host "   $_" }
if ($smokeCode -ne 0) { Die "自检失败 (exit $smokeCode)" }
Ok '自检通过：DLL 在无 JAPI 环境里安全降级，日志正常写出，进程未崩溃'

$smokeLog = Join-Path $logDir 'UDamageProbe.log'
if (Test-Path $smokeLog) {
	Ok "自检日志: $smokeLog"
} else {
	Die "自检没有产生日志: $smokeLog"
}

#------------------------------------------------------------------------------
# 6. 安装 DLL
#------------------------------------------------------------------------------
Step '6/8 安装 DLL 到 warcraft3\'

if ($SkipInstall) {
	Warn '-SkipInstall：跳过安装'
} else {
	if (-not (Test-Path $pluginDir)) { Die "插件目录不存在: $pluginDir" }
	$dstDll = Join-Path $pluginDir 'UDamageProbe.dll'
	Copy-Item $dllOut $dstDll -Force
	Ok ("已安装: {0} ({1:N0} 字节)" -f $dstDll, (Get-Item $dstDll).Length)

	#----------------------------------------------------------------------------
	# 7. 在 config.cfg（GBK）里登记
	#----------------------------------------------------------------------------
	Step '7/8 在 warcraft3\config.cfg 里登记 UDamageProbe.dll = 1'

	$cfg     = Join-Path $pluginDir 'config.cfg'
	$cfgBak  = Join-Path $pluginDir 'config.cfg.probe.bak'
	$gbk     = [System.Text.Encoding]::GetEncoding(936)

	if (-not (Test-Path $cfg)) { Die "找不到 config.cfg: $cfg" }

	# 备份（只在首次备份，保护用户原始文件）
	if (-not (Test-Path $cfgBak)) {
		Copy-Item $cfg $cfgBak -Force
		Ok "已备份原始 config.cfg -> $cfgBak"
	} else {
		Info "备份已存在，保持不动: $cfgBak"
	}

	$cfgText = $gbk.GetString([System.IO.File]::ReadAllBytes($cfg))
	$lines   = @($cfgText -split "`r`n|`n") | Where-Object { $_ -ne '' }

	$already = $false
	foreach ($l in $lines) {
		if ($l -match '^\s*UDamageProbe\.dll\s*=') { $already = $true; break }
	}

	if ($already) {
		Ok 'config.cfg 里已经登记过 UDamageProbe.dll，跳过（幂等）'
	} else {
		# 只追加一行，不改动其它任何行
		$newText = $cfgText
		if (-not $newText.EndsWith("`r`n") -and -not $newText.EndsWith("`n")) {
			$newText += "`r`n"
		}
		$newText += 'UDamageProbe.dll = 1' + "`r`n"
		[System.IO.File]::WriteAllBytes($cfg, $gbk.GetBytes($newText))
		Ok '已在 config.cfg 追加一行: UDamageProbe.dll = 1'
	}

	# 回读确认
	$after = $gbk.GetString([System.IO.File]::ReadAllBytes($cfg))
	Info '--- config.cfg 现在的内容 ---'
	$after -split "`r`n" | Where-Object { $_ -ne '' } | ForEach-Object { Write-Host "   $_" }

	if ($already) {
		# 幂等路径：本次根本没写文件，不需要也不可能做差异确认。
		# （$lines 是从"已经登记过"的文件读出来的，拿它当作"改动前"必然是错的。）
		Ok '本次未修改 config.cfg（幂等），跳过差异确认'
	} else {
		# 确认其它行没被改动。
		# $lines 是写入之前读出来的快照，必须排除空元素后再 join，
		# 否则会凭空多出一个换行，造成"只追加了一行"的假警告。
		$before = ($lines | Where-Object { $_ -ne '' }) -join "`n"
		$afterLines = @(($after -split "`r`n|`n")) |
			Where-Object { $_ -ne '' -and $_ -notmatch '^\s*UDamageProbe\.dll\s*=' }
		$afterKey = ($afterLines | Where-Object { $_ -ne '' }) -join "`n"
		if ($before -ne $afterKey) {
			Warn '警告：config.cfg 除了追加那一行之外似乎还有别的差异，请人工核对备份文件'
			Compare-Object ($before -split "`n") ($afterKey -split "`n") |
				ForEach-Object { Write-Host ("   {0} {1}" -f $_.SideIndicator, $_.InputObject) }
		} else {
			Ok '确认：config.cfg 只多了这一行，其它行未改动'
		}
	}
}

#------------------------------------------------------------------------------
# 8. 汇总 + 测试步骤
#------------------------------------------------------------------------------
Step '8/8 完成'

$finalDll = Join-Path $pluginDir 'UDamageProbe.dll'
$gameLog  = Join-Path $pluginDir 'UDamageProbe.log'

Write-Host ''
Ok '============================================================'
Ok ' 构建 + 自检完成'
Ok '============================================================'
Write-Host (" 产物 DLL   : {0}" -f $dllOut)
if (-not $SkipInstall) {
	Write-Host (" 已安装到   : {0}" -f $finalDll)
	Write-Host (" 配置备份   : {0}" -f (Join-Path $pluginDir 'config.cfg.probe.bak'))
	Write-Host (" 游戏内日志 : {0}" -f $gameLog)
}
Write-Host (" 自检日志   : {0}" -f (Join-Path $logDir 'UDamageProbe.log'))
Write-Host ''
Write-Host ' 测试步骤：' -ForegroundColor Yellow
Write-Host '   1) 关掉所有魔兽进程'
Write-Host ("   2) 双击启动器: {0}" -f (Resolve-Path (Join-Path $root '..\启动魔兽.bat') -ErrorAction SilentlyContinue))
Write-Host '   3) 进一张地图，随便让一个单位挨打（普通攻击即可），然后退出游戏'
Write-Host ("   4) 打开日志看: {0}" -f $gameLog)
Write-Host ''
Write-Host ' 卸载：' -ForegroundColor Yellow
Write-Host '   * 删掉 warcraft3\UDamageProbe.dll'
Write-Host '   * 从 warcraft3\config.cfg 里删掉 "UDamageProbe.dll = 1" 那一行'
Write-Host '     （或直接用 config.cfg.probe.bak 覆盖回去）'
Write-Host ''
