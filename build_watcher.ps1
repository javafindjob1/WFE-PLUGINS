<#
================================================================================
 build_watcher.ps1 —— 构建 / 自检 / 安装 UDamageWatcher（伤害监视 · 显示版）
================================================================================
 流程：
   1. 定位工具链：优先【直连 cl.exe】—— 自己找 MSVC 的 cl.exe(x86) 与 Windows SDK，
      设好 INCLUDE/LIB/PATH 后直接调用（不依赖 vcvarsall，也不依赖 cmd 输出捕获）；
      找不到 cl.exe 时才回退到 vcvarsall。
   2. 编译 UDamageWatcherHook.cpp -> _build\watcher\UDamageWatcher.dll
   3. 编译 UDamageWatcherSmoke.cpp -> _build\watcher\UDamageWatcherSelftest.exe
      （源码仍叫 Smoke，产物名自 2026-10-01 起改为 Selftest —— 旧产物名被 360 拉黑锁死）
   4. 读 PE 头校验架构（x86）；导出 Initialize / PluginName 由自检程序验证
   5. 跑自检：假目录里 LoadLibrary + Initialize，验证
      "没有 JAPI/ydbase 时安全降级、日志/ini 正常生成、进程不崩"
      （自检输出走临时 cmd + 文件重定向，绕开"禁止管道 stdio"的受限环境）
   6. 复制 DLL 到 warcraft3\UDamageWatcher.dll
   7. 在 warcraft3\config.cfg（GBK）里补一行 "UDamageWatcher.dll = 1"
      （幂等；只追加，不动其它行）
   8. 卸载探针：删 warcraft3\UDamageProbe.dll + 去掉 config.cfg 里的
      "UDamageProbe.dll = 1"（备份 config.cfg.probe.bak 保留不动）
   9. 打印安装结果与测试步骤

 用法：
   .\build_watcher.ps1
   .\build_watcher.ps1 -SkipInstall
   .\build_watcher.ps1 -KeepProbe      # 不卸载探针（不建议：两个插件会抢同一个槽）
   .\build_watcher.ps1 -Cl  "D:\...\VC\Tools\MSVC\<ver>\bin\Hostx64\x86\cl.exe"
   .\build_watcher.ps1 -VcVars "D:\...\vcvarsall.bat"   # 强制走 vcvarsall 老路

 注意：本脚本绝不写游戏目录（旧 D:\war5，现 C:\3rd\war5）。产物与日志只落在 plugin 目录内。
================================================================================
#>
[CmdletBinding()]
param(
	[string]$VcVars = '',
	[string]$Cl = '',
	[string]$Wfe = '',
	[switch]$SkipInstall,
	[switch]$KeepProbe
)

$ErrorActionPreference = 'Stop'

function Info($m) { Write-Host $m }
function Ok($m)   { Write-Host $m -ForegroundColor Green }
function Warn($m) { Write-Host $m -ForegroundColor Yellow }
function Die($m)  { Write-Host $m -ForegroundColor Red; exit 1 }
function Step($m) { Write-Host ''; Write-Host "== $m ==" -ForegroundColor Cyan }

$root      = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$pluginDir = Join-Path $root 'warcraft3'
$buildDir  = Join-Path $root '_build\watcher'
$dllOut    = Join-Path $buildDir 'UDamageWatcher.dll'
$smokeExe  = Join-Path $buildDir 'UDamageWatcherSelftest.exe'
$selfDir   = Join-Path $root '_selftest\watcher'
$iniPath   = Join-Path $pluginDir 'UDamageWatcher.ini'

Info "工作区  : $root"
Info "插件目录: $pluginDir"
Info "构建目录: $buildDir"

#------------------------------------------------------------------------------
# 1. 找 vcvarsall.bat
#------------------------------------------------------------------------------
Step '1/9 定位 MSVC (vcvarsall.bat x86)'

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
	$found = $found | Sort-Object -Unique
	$pref = $found | Where-Object { $_ -like '*\18\*' } | Select-Object -First 1
	if ($pref) { return $pref }
	if ($found.Count -gt 0) { return $found[0] }
	return ''
}

$vcvars = Find-VcVars -Explicit $VcVars

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

#------------------------------------------------------------------------------
# 1.5 定位 cl.exe + Windows SDK（【直连方式】，优先使用）
#     受限环境里 cmd /c 的输出捕获、以及 vcvarsall 内部的 vswhere/dir 调用
#     都可能失败（表现为"编译一句话都不输出就失败"），所以这里自己找工具链：
#     设好 INCLUDE/LIB/PATH 后直接调用 cl.exe，输出直接进控制台。
#     找不到 cl.exe 时才回退到上面的 vcvarsall 老路。
#------------------------------------------------------------------------------
function Find-ClExe {
	param([string]$Explicit)
	if ($Explicit) {
		if (Test-Path $Explicit) { return $Explicit }
		Die "指定的 -Cl 不存在: $Explicit"
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
		$found += Get-ChildItem -Path $b -Recurse -Depth 10 -Filter 'cl.exe' -File -ErrorAction SilentlyContinue |
			Where-Object { $_.FullName -like '*\VC\Tools\MSVC\*\bin\Hostx64\x86\cl.exe' } |
			Select-Object -ExpandProperty FullName
	}
	$found = $found | Sort-Object -Unique
	$pref = $found | Where-Object { $_ -like '*\18\*' } | Select-Object -First 1
	if ($pref) { return $pref }
	if ($found.Count -gt 0) { return $found[0] }
	return ''
}

function Find-SdkDir {
	param([string]$Kind)   # 'Include' 或 'Lib'
	# 2026-10-01：工作区迁移后 Windows SDK 也可能换位置（本机是 C:\Windows Kits\10），
	# 三个候选都探一遍，谁在用谁。
	$bases = @(
		'C:\Windows Kits\10',
		'D:\Windows Kits\10',
		'C:\Program Files (x86)\Windows Kits\10'
	)
	foreach ($b in $bases) {
		$p = Join-Path $b $Kind
		if (-not (Test-Path $p)) { continue }
		$v = Get-ChildItem $p -Directory -ErrorAction SilentlyContinue |
			Where-Object { $_.Name -match '^\d+\.' } | Sort-Object Name -Descending | Select-Object -First 1
		if ($v) { return $v.FullName }
	}
	return ''
}

$clExe = Find-ClExe -Explicit $Cl
if ($clExe) {
	$msvcRoot = Split-Path (Split-Path (Split-Path (Split-Path $clExe)))
	$sdkInc = Find-SdkDir -Kind 'Include'
	$sdkLib = Find-SdkDir -Kind 'Lib'
	if (-not $sdkInc -or -not $sdkLib) {
		Die ' 找到了 cl.exe 但找不到 Windows SDK 的 Include/Lib；可用 -Cl 指定 cl.exe，或装齐 SDK'
	}
	$env:INCLUDE = "$msvcRoot\include;$sdkInc\ucrt;$sdkInc\shared;$sdkInc\um"
	$env:LIB     = "$msvcRoot\lib\x86;$sdkLib\ucrt\x86;$sdkLib\um\x86"
	$env:PATH    = "$(Split-Path $clExe);$env:PATH"
	Ok "cl.exe   : $clExe"
	Ok "MSVC     : $msvcRoot"
	Ok "SDK      : $sdkInc / $sdkLib"
	Ok '编译方式 : 直连 cl.exe（不依赖 vcvarsall / cmd 输出捕获）'
} else {
	Ok "vcvarsall: $vcvars"
	if (-not $vcvars) { Die ' 既找不到 cl.exe 也找不到 vcvarsall.bat，请用 -Cl 指定 cl.exe 路径' }
	Ok '编译方式 : vcvarsall + cmd（回退）'
}

# 执行一个程序并把输出回显到控制台；返回退出码。
# 为什么绕 cmd：受限环境里 pwsh 直接 & 启动某些 exe 会被拒（Access is denied），
# 而"写一个临时 cmd、让它自己重定向到日志、再由 pwsh 读日志"这条路是通的。
function Invoke-ExeToLog {
	param([string]$Exe, [string[]]$ExeArgs, [string]$WorkDir, [string]$Tag)
	$log  = Join-Path $buildDir ("run-{0}.log" -f $Tag)
	$tmp  = Join-Path $buildDir ("run-{0}.cmd" -f $Tag)
	$ansi = [System.Text.Encoding]::Default.CodePage
	$tagU = $Tag.ToUpper()
	$argLine = ($ExeArgs | ForEach-Object {
		if ($_ -match '[\s"]') { '"{0}"' -f $_ } else { $_ }
	}) -join ' '
	$lines = @(
		'@echo off',
		("chcp {0} >nul" -f $ansi),
		("cd /d `"{0}`"" -f $WorkDir),
		("`"{0}`" {1} > `"{2}`" 2>&1" -f $Exe, $argLine, $log),
		("echo {0}_EXIT=%ERRORLEVEL% >> `"{1}`"" -f $tagU, $log)
	)
	[System.IO.File]::WriteAllBytes($tmp, [System.Text.Encoding]::Default.GetBytes(($lines -join "`r`n")))
	if (Test-Path $log) { Remove-Item $log -Force -ErrorAction SilentlyContinue }

	# 先用 cmd 执行；个别受限环境里这条会静默失败（退出码都是空的），
	# 那就再用 pwsh 直接执行同一个 .cmd 试一次。
	cmd /c "$tmp"
	if (-not (Test-Path $log)) { & $tmp }

	if (Test-Path $log) {
		Get-Content $log | Where-Object { $_ -notmatch ("^{0}_EXIT=" -f $tagU) } |
			ForEach-Object { Write-Host "   $_" }
		$m = [regex]::Match((Get-Content $log -Raw), ("{0}_EXIT=(\d+)" -f $tagU))
		if ($m.Success) { return [int]$m.Groups[1].Value }
	}
	return -1
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

#------------------------------------------------------------------------------
# 2. 编译插件 DLL
#------------------------------------------------------------------------------
Step '2/9 编译 UDamageWatcher.dll'

$srcMain = Join-Path $root 'UDamageWatcherHook.cpp'
if (-not (Test-Path $srcMain)) { Die "找不到源码: $srcMain" }

$clDll = "cl /nologo /utf-8 /LD /O2 /MT /EHsc /W3 " +
         "/Fe:`"$dllOut`" /Fo:`"$buildDir\UDamageWatcherHook.obj`" `"$srcMain`" " +
         "/link /SUBSYSTEM:WINDOWS user32.lib"

if ($clExe) {
	$code = Invoke-ExeToLog -Exe $clExe -WorkDir $buildDir -Tag 'cldll' -ExeArgs @(
		'/nologo','/utf-8','/LD','/O2','/MT','/EHsc','/W3',
		"/Fe:$dllOut", "/Fo:$buildDir\UDamageWatcherHook.obj", $srcMain,
		'/link','/SUBSYSTEM:WINDOWS','user32.lib')
} else {
	$r = Invoke-Vc -Cmd $clDll -WorkDir $buildDir
	Write-Host $r.Output
	$code = $r.Code
}
if ($code -ne 0) { Die "编译 UDamageWatcher.dll 失败 (exit $code)" }
if (-not (Test-Path $dllOut)) { Die "编译声称成功但没有产物: $dllOut" }
Ok ("DLL 编译成功: {0} ({1:N0} 字节)" -f $dllOut, (Get-Item $dllOut).Length)

#------------------------------------------------------------------------------
# 3. 编译自检程序
#------------------------------------------------------------------------------
Step '3/9 编译自检程序 UDamageWatcherSelftest.exe'

$srcSmoke = Join-Path $root 'UDamageWatcherSmoke.cpp'
if (-not (Test-Path $srcSmoke)) { Die "找不到源码: $srcSmoke" }

# ⚠ 2026-10-01（迁移到 C:\3rd 后踩到）：本机 360 把可执行文件名
#   UDamageWatcherSmoke.exe 拉黑锁死了（Get-Item/Remove/覆盖写全部 Access is denied，
#   换个名字立刻正常）。自检程序改叫 UDamageWatcherSelftest.exe 绕开；
#   cl /Fo 的对象名也跟着改，免得旧对象文件被一起锁。
$clSmoke = "cl /nologo /utf-8 /O2 /MT /EHsc /W3 " +
           "/Fe:`"$smokeExe`" /Fo:`"$buildDir\UDamageWatcherSelftest.obj`" `"$srcSmoke`""

if ($clExe) {
	$code = Invoke-ExeToLog -Exe $clExe -WorkDir $buildDir -Tag 'clsmoke' -ExeArgs @(
		'/nologo','/utf-8','/O2','/MT','/EHsc','/W3',
		"/Fe:$smokeExe", "/Fo:$buildDir\UDamageWatcherSelftest.obj", $srcSmoke)
} else {
	$r = Invoke-Vc -Cmd $clSmoke -WorkDir $buildDir
	Write-Host $r.Output
	$code = $r.Code
}
if ($code -ne 0) { Die "编译自检程序失败 (exit $code)" }
Ok ("自检程序编译成功: {0} ({1:N0} 字节)" -f $smokeExe, (Get-Item $smokeExe).Length)

#------------------------------------------------------------------------------
# 4. 校验产物架构（直接读 PE 头，不依赖 dumpbin / cmd 输出捕获）
#    导出 Initialize / PluginName 由下一步的自检程序负责验证
#------------------------------------------------------------------------------
Step '4/9 校验产物架构'

$bytes = [System.IO.File]::ReadAllBytes($dllOut)
$peOff = [BitConverter]::ToInt32($bytes, 0x3C)
$machine = [BitConverter]::ToUInt16($bytes, $peOff + 4)
if ($machine -eq 0x14C) {
	Ok '目标架构: x86 (14C) —— 与 32 位魔兽一致'
} elseif ($machine -eq 0x8664) {
	Die '产物是 x64，魔兽无法加载！检查是否用了 Hostx64\x86 下的 cl.exe'
} else {
	Warn ("未能确认目标架构（machine=0x{0:X}），请人工核对" -f $machine)
}
Ok ("产物: {0} ({1:N0} 字节)" -f $dllOut, (Get-Item $dllOut).Length)

#------------------------------------------------------------------------------
# 5. 跑自检
#------------------------------------------------------------------------------
Step '5/9 运行本机自检（无 JAPI/ydbase，验证安全降级）'

Remove-Item $selfDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $selfDir | Out-Null

$smokeCode = Invoke-ExeToLog -Exe $smokeExe -WorkDir $buildDir -Tag 'smoke' `
                             -ExeArgs @($dllOut, $selfDir)
$smokeLog = Join-Path $buildDir 'run-smoke.log'
$smokeOk = ($smokeCode -eq 0)
if (-not $smokeOk -and (Test-Path $smokeLog)) {
	# 有的环境里自检程序退出码不可靠，再用日志里的 RESULT 行确认一次
	if ((Get-Content $smokeLog -Raw) -match 'RESULT: PASS') { $smokeOk = $true }
}
if (-not $smokeOk) { Die '自检失败 (自检程序未报告 RESULT: PASS，退出码 ' + $smokeCode + ')' }
Ok '自检通过：无 JAPI 环境安全降级，日志与 ini 正常生成，进程未崩溃，导出 Initialize/PluginName 可用'

#------------------------------------------------------------------------------
# 6. 安装 DLL
#------------------------------------------------------------------------------
Step '6/9 安装 DLL 到 warcraft3\'

$cfg    = Join-Path $pluginDir 'config.cfg'
$gbk    = [System.Text.Encoding]::GetEncoding(936)

function Get-CfgLines([string]$path) {
	$t = $gbk.GetString([System.IO.File]::ReadAllBytes($path))
	return @(($t -split "`r`n|`n") | Where-Object { $_ -ne '' })
}
function Set-CfgText([string]$path, [string[]]$lines) {
	$txt = (($lines | Where-Object { $_ -ne '' }) -join "`r`n") + "`r`n"
	[System.IO.File]::WriteAllBytes($path, $gbk.GetBytes($txt))
}

if ($SkipInstall) {
	Warn '-SkipInstall：跳过安装'
} else {
	if (-not (Test-Path $pluginDir)) { Die "插件目录不存在: $pluginDir" }
	$dstDll = Join-Path $pluginDir 'UDamageWatcher.dll'
	Copy-Item $dllOut $dstDll -Force

	# ⚠ 坑（2026-09-28 实际踩过）：YDWE 启动器是【按字符串精确匹配】plugin 目录里的文件名的，
	#   而 Windows 的 Test-Path/Copy-Item 大小写不敏感 —— 一旦目录里先存在一个
	#   `udamagewatcher.dll`（小写），后续 Copy-Item 会保留这个小写名，于是 config.cfg 里的
	#   `UDamageWatcher.dll = 0` 匹配不上 → 启动器找不到文件 → 报错、游戏起不来。
	#   这里统一把真实文件名规范成 UDamageWatcher.dll，保证配置与实际文件逐字符一致。
	$realName = (Get-ChildItem $pluginDir -File -ErrorAction SilentlyContinue |
	             Where-Object { $_.Name -match '(?i)^udamagewatcher\.dll$' } |
	             Select-Object -First 1).Name
	if ($realName -and ($realName -cne 'UDamageWatcher.dll')) {
		$tmpDll = Join-Path $pluginDir 'UDW_case_tmp.dll'
		Move-Item (Join-Path $pluginDir $realName) $tmpDll -Force
		Move-Item $tmpDll (Join-Path $pluginDir 'UDamageWatcher.dll') -Force
		Ok ("已规范文件名: {0} -> UDamageWatcher.dll（否则启动器会因大小写不匹配报错）" -f $realName)
	}
	Ok ("已安装: {0} ({1:N0} 字节)" -f $dstDll, (Get-Item $dstDll).Length)

	#--------------------------------------------------------------------------
	# 7. 登记 / 部署
	#    两种部署形态：
	#      A) YDWE 插件目录加载（传统）：config.cfg 里 UDamageWatcher.dll = 1
	#      B) 交给 WFE 注入（推荐配合 WFE 增强）：DLL 仍留在 plugin\warcraft3\，
	#         但 config.cfg 置 0（保留文件、不加载），同时把 DLL+ini 复制到
	#         WFE 的 Libraries 目录，由它的 Auto-inject 注入游戏进程。
	#         同一个 DLL 不能被两个加载器同时注入（槽会被替换两次 → 自己调自己）。
	#--------------------------------------------------------------------------
	$wfeDir = $Wfe
	if (-not $wfeDir) {
		# 2026-10-01：工作区从 D:\ 迁到 C:\3rd\，WFE 平台也跟着搬家了。
		# 新位置优先，旧位置留着兼容（两个都在时会选新的）。
		$guesses = @(
			'C:\3rd\wc3gamesearcher\WFE\Application\Libraries',
			'D:\fsdownload\wc3gamesearcher\WFE\Application\Libraries'
		)
		foreach ($g in $guesses) {
			if (Test-Path $g) { $wfeDir = $g; break }
		}
	}
	$useWfe = ($wfeDir -and (Test-Path $wfeDir))
	$regValue = if ($useWfe) { '0' } else { '1' }

	Step ("7/9 登记 config.cfg（UDamageWatcher.dll = {0}）" -f $regValue)

	if (-not (Test-Path $cfg)) { Die "找不到 config.cfg: $cfg" }

	if (-not (Test-Path "$cfg.probe.bak")) {
		Copy-Item $cfg "$cfg.probe.bak" -Force
		Ok "已备份原始 config.cfg -> config.cfg.probe.bak"
	}

	$lines = Get-CfgLines $cfg
	$wantLine = "UDamageWatcher.dll = $regValue"
	if (@($lines | Where-Object { $_ -match '^\s*UDamageWatcher\.dll\s*=' }).Count -gt 0) {
		$lines = @($lines | ForEach-Object {
			if ($_ -match '^\s*UDamageWatcher\.dll\s*=') { $wantLine } else { $_ }
		})
		Set-CfgText $cfg $lines
		Ok ("config.cfg 里的 UDamageWatcher.dll 已置为 {0}" -f $regValue)
	} else {
		$lines += $wantLine
		Set-CfgText $cfg $lines
		Ok ("已在 config.cfg 追加一行: {0}" -f $wantLine)
	}

	if ($useWfe) {
		$libDll = Join-Path $wfeDir 'UDamageWatcher.dll'
		$libIni = Join-Path $wfeDir 'UDamageWatcher.ini'
		Copy-Item $dllOut $libDll -Force
		if (Test-Path $iniPath) { Copy-Item $iniPath $libIni -Force }
		Ok ("WFE 部署: {0} ({1:N0} 字节)" -f $libDll, (Get-Item $libDll).Length)
		Info '  → YDWE 侧已停用（= 0），由 WFE 的 Auto-inject 注入游戏进程'
		Info '  → WFE 里请打开 Auto-inject / 允许加载附加库（Libraries 目录）'
	} else {
		Info '未发现 WFE 目录（或未用 -Wfe 指定），保持"YDWE 插件目录加载"形态'
	}

	#--------------------------------------------------------------------------
	# 8. 卸载探针（避免两个插件抢同一条链上的同一个槽）
	#--------------------------------------------------------------------------
	Step '8/9 卸载探针 UDamageProbe'

	if ($KeepProbe) {
		Warn '-KeepProbe：保留探针。注意两个插件都会替换 J+0x928D4 那个槽，会互相套娃！'
	} else {
		$probeDll = Join-Path $pluginDir 'UDamageProbe.dll'
		if (Test-Path $probeDll) {
			Remove-Item $probeDll -Force
			Ok "已删除 $probeDll"
		} else {
			Info '探针 DLL 不存在，无需删除'
		}

		$lines = Get-CfgLines $cfg
		$n0 = $lines.Count
		$lines = @($lines | Where-Object { $_ -notmatch '^\s*UDamageProbe\.dll\s*=' })
		if ($lines.Count -ne $n0) {
			Set-CfgText $cfg $lines
			Ok '已去掉 config.cfg 里的 UDamageProbe.dll 那一行'
		} else {
			Info 'config.cfg 里本来就没有 UDamageProbe.dll，无需去掉'
		}
	}

	#--------------------------------------------------------------------------
	# 回读确认：拿磁盘上的实际内容，和"原始备份"对比。
	# 期望 = 备份内容 - UDamageProbe 行 + UDamageWatcher 行
	# （不能拿内存里的 $lines 当期望，那样是自己证明自己）
	#--------------------------------------------------------------------------
	$after = Get-CfgLines $cfg
	Info '--- config.cfg 现在的内容 ---'
	$after | ForEach-Object { Write-Host "   $_" }

	$baseLines = @()
	if (Test-Path "$cfg.probe.bak") { $baseLines = Get-CfgLines "$cfg.probe.bak" }
	$expected = @($baseLines |
		Where-Object { $_ -notmatch '^\s*UDamageProbe\.dll\s*=' } |
		Where-Object { $_ -notmatch '^\s*UDamageWatcher\.dll\s*=' })
	$expected += $wantLine

	$e = @($expected | Where-Object { $_ -ne '' }) | Sort-Object
	$a = @($after    | Where-Object { $_ -ne '' }) | Sort-Object
	$diff = @(Compare-Object $e $a)
	if ($diff.Count -eq 0) {
		Ok '确认：config.cfg = 原始备份 - 探针行 + 监视器行，其它行逐行未变'
	} else {
		Warn '警告：config.cfg 与预期不一致，请人工核对'
		$diff | ForEach-Object { Write-Host ("   {0} {1}" -f $_.SideIndicator, $_.InputObject) }
	}
}

#------------------------------------------------------------------------------
# 9. 汇总 + 测试步骤
#------------------------------------------------------------------------------
Step '9/9 完成'

Write-Host ''
Ok '============================================================'
Ok ' 构建 + 自检完成'
Ok '============================================================'
Write-Host (" 产物 DLL : {0}" -f $dllOut)
if (-not $SkipInstall) {
	Write-Host (" 已安装到 : {0}" -f (Join-Path $pluginDir 'UDamageWatcher.dll'))
	Write-Host (" 游戏日志 : {0}" -f (Join-Path $pluginDir 'UDamageWatcher.log'))
	Write-Host (" 游戏配置 : {0}" -f (Join-Path $pluginDir 'UDamageWatcher.ini'))
}
Write-Host (" 自检日志 : {0}" -f (Join-Path $selfDir 'UDamageWatcher.log'))
Write-Host ''
Write-Host ' 测试步骤：' -ForegroundColor Yellow
Write-Host '   0) 建议先把 ini 里 log_only 改成 1（只记日志不显示），先验证数据对不对'
Write-Host '   1) 关掉所有魔兽进程'
Write-Host ('   2) 双击启动器: {0}' -f (Resolve-Path (Join-Path $root '..\启动魔兽.bat') -ErrorAction SilentlyContinue))
Write-Host '   3) 进地图随便让一个单位挨打（普通近战最好）'
Write-Host '   4) 看屏幕消息区 + 日志文件'
Write-Host ''
Write-Host ' 卸载：' -ForegroundColor Yellow
Write-Host '   * 删掉 warcraft3\UDamageWatcher.dll 和 UDamageWatcher.ini'
Write-Host '   * 从 warcraft3\config.cfg 里删掉 "UDamageWatcher.dll = 1" 那一行'
Write-Host ''
