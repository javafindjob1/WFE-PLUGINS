param(
    [int]$Seconds = 30
)

$ErrorActionPreference = "Stop"

# 游戏如果是管理员权限运行，非管理员测试程序打不开它的进程，会只写启动行、不注入。
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "FAIL: 测试需要管理员权限（游戏通常是管理员启动的）。"
    Write-Host "请右键 头像测试.cmd → 以管理员身份运行。"
    exit 1
}

$root = $PSScriptRoot
$publishDir = Join-Path $root "publish"
$app = Join-Path $publishDir "War3DeathSettlement.exe"
$testScript = Join-Path $root "test_avatar.ps1"

# 如果脚本本身就在 publish 目录（用户双击 publish\头像测试.cmd），直接用当前目录。
if (-not (Test-Path $app)) {
    $app2 = Join-Path $root "War3DeathSettlement.exe"
    $test2 = Join-Path $root "test_avatar.ps1"
    if (Test-Path $app2) {
        $publishDir = $root
        $app = $app2
        $testScript = $test2
    }
}

if (-not (Test-Path $app)) {
    Write-Host "FAIL: 找不到 $app"
    Write-Host "请把本脚本放在 DeathSettlement 根目录，或和 War3DeathSettlement.exe 放在同一目录。"
    exit 1
}
if (-not (Test-Path $testScript)) {
    Write-Host "FAIL: 找不到 $testScript"
    exit 1
}


# 释放 Roslyn/MSBuild 编译服务器对刚构建 DLL 的占用；这和游戏/主程序无关。
try { dotnet build-server shutdown 2>$null | Out-Null } catch { }

# 测试必须用无界面 --monitor 启动；主界面已经开着时，单实例会转去现有 GUI，不会自动预览。
$old = Get-Process War3DeathSettlement -ErrorAction SilentlyContinue
if ($old) {
    Write-Host "请先完全关闭正在运行的 War3DeathSettlement 主界面，再运行本测试。"
    Write-Host "（主界面打开时不会自动发预览；你也可以在主界面点【游戏内预览】手动看面板。）"
    exit 1
}

Write-Host "启动面板测试程序（$Seconds 秒）..."
$p = Start-Process -FilePath $app `
    -ArgumentList @("--monitor", "--hook", "--panel-test", "--seconds", "$Seconds") `
    -WorkingDirectory $publishDir `
    -PassThru -WindowStyle Hidden

Start-Sleep -Seconds 2
& powershell -NoProfile -ExecutionPolicy Bypass -File $testScript -WaitSeconds ([Math]::Max(5, $Seconds - 3))
$code = $LASTEXITCODE
if ($p -and -not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
exit $code
