[CmdletBinding()]
param(
    [string]$Version = '2.2.11',
    [string]$OutputRoot = '',
    [string]$NuGetSource = 'https://api.nuget.org/v3/index.json'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (-not $OutputRoot) {
    $OutputRoot = Join-Path $root 'release'
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$packageName = "War3DeathSettlement-v$Version-$stamp"
$packageDir = Join-Path $OutputRoot $packageName
$zipPath = Join-Path $OutputRoot ($packageName + '.zip')
if (Test-Path -LiteralPath $packageDir) { throw "Package directory already exists: $packageDir" }
if (Test-Path -LiteralPath $zipPath) { throw "Package zip already exists: $zipPath" }

$desktopDir = Join-Path $packageDir 'Desktop'
$desktopHookDir = Join-Path $desktopDir 'hook'
$gameDir = Join-Path $packageDir 'Game'
$wfeDir = Join-Path $gameDir 'WFE-Libraries'
New-Item -ItemType Directory -Force -Path $desktopDir, $desktopHookDir, $wfeDir | Out-Null

Write-Host '== build Vue ==' -ForegroundColor Cyan
Push-Location (Join-Path $root 'web')
try {
    npm run build
    if ($LASTEXITCODE -ne 0) { throw "Vue build failed ($LASTEXITCODE)" }
}
finally {
    Pop-Location
}

Write-Host '== publish desktop ==' -ForegroundColor Cyan
dotnet publish (Join-Path $root 'DesktopHost\War3DeathSettlement.Desktop.csproj') `
    -c Release -r win-x64 --self-contained true `
    -o $desktopDir `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:EnableCompressionInSingleFile=true `
    --nologo `
    --source $NuGetSource
if ($LASTEXITCODE -ne 0) { throw "Desktop publish failed ($LASTEXITCODE)" }

Write-Host '== collect game files ==' -ForegroundColor Cyan
Copy-Item -LiteralPath (Join-Path $root '_test\hook\ddh.dll') -Destination $wfeDir -Force
Copy-Item -LiteralPath (Join-Path $root '_test\hook\ddh.dll') -Destination $desktopHookDir -Force
Copy-Item -LiteralPath (Join-Path $root '_test\hook\ddh_inject.exe') -Destination $desktopHookDir -Force

$desktopDocs = @(
    @{ Source = 'README.md'; Name = 'README.md' }
)
foreach ($doc in $desktopDocs) {
    Copy-Item -LiteralPath (Join-Path $root $doc.Source) -Destination (Join-Path $packageDir $doc.Name) -Force
}
Copy-Item -LiteralPath (Join-Path $root 'tools\install_release.ps1') -Destination $packageDir -Force
Copy-Item -LiteralPath (Join-Path $root 'tools\install_release.cmd') -Destination $packageDir -Force
Copy-Item -LiteralPath (Join-Path $root 'tools\release-notes.txt') `
    -Destination (Join-Path $packageDir 'INSTALL.txt') -Force

if (Test-Path -LiteralPath (Join-Path $wfeDir 'dss.html')) {
    throw 'dss.html must not be placed in WFE-Libraries'
}
if (Test-Path -LiteralPath (Join-Path $wfeDir 'dss-assets')) {
    throw 'dss-assets must not be placed in WFE-Libraries'
}
if (Test-Path -LiteralPath (Join-Path $wfeDir 'ddh_core.bin')) {
    throw 'ddh_core.bin must not be included; the injected module is a single ddh.dll'
}
if (-not (Test-Path -LiteralPath (Join-Path $wfeDir 'ddh.dll'))) {
    throw 'Missing ddh.dll in WFE-Libraries'
}
if (-not (Test-Path -LiteralPath (Join-Path $desktopHookDir 'ddh.dll'))) {
    throw 'Missing ddh.dll for standalone Desktop mode'
}
if (-not (Test-Path -LiteralPath (Join-Path $desktopHookDir 'ddh_inject.exe'))) {
    throw 'Missing ddh_inject.exe for standalone Desktop mode'
}
if (Test-Path -LiteralPath (Join-Path $gameDir 'ddh_web')) {
    throw 'Game-side ddh_web must not be included in the desktop-only release'
}

$commit = (git -C $root rev-parse --short HEAD).Trim()
$builtAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
$info = @(
    "Product=War3DeathSettlement"
    "Version=$Version"
    "BuildTime=$builtAt"
    "Commit=$commit"
    "Package=$packageName"
)
[IO.File]::WriteAllLines(
    (Join-Path $packageDir 'BUILD-INFO.txt'),
    $info,
    (New-Object Text.UTF8Encoding($false)))

Get-ChildItem -Path $desktopDir -Filter '*.pdb' -File -ErrorAction SilentlyContinue |
    Remove-Item -Force
Get-ChildItem -Path $desktopDir -Filter '*.xml' -File -ErrorAction SilentlyContinue |
    Remove-Item -Force

Write-Host '== hashes ==' -ForegroundColor Cyan
$hashFile = Join-Path $packageDir 'SHA256SUMS.txt'
$hashLines = Get-ChildItem -Path $packageDir -Recurse -File |
    Where-Object { $_.FullName -ne $hashFile } |
    Sort-Object FullName |
    ForEach-Object {
        $relative = $_.FullName.Substring($packageDir.Length + 1).Replace('\', '/')
        $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        "$hash  $relative"
    }
[IO.File]::WriteAllLines($hashFile, $hashLines, (New-Object Text.UTF8Encoding($false)))

Write-Host '== zip ==' -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
Compress-Archive -Path $packageDir -DestinationPath $zipPath -CompressionLevel Optimal

Write-Host ''
Write-Host "PACKAGE_DIR=$packageDir" -ForegroundColor Green
Write-Host "PACKAGE_ZIP=$zipPath" -ForegroundColor Green
$sizeMb = [Math]::Round((Get-Item -LiteralPath $zipPath).Length / 1MB, 2)
Write-Host "PACKAGE_SIZE_MB=$sizeMb" -ForegroundColor Green
