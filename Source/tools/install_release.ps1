[CmdletBinding()]
param(
    [string]$WfeLibraries = 'C:\3rd\wc3gamesearcher\WFE\Application\Libraries',
    [string]$LaunchDirectory = 'C:\launch'
)

$ErrorActionPreference = 'Stop'
$packageRoot = $PSScriptRoot
$sourceWfe = Join-Path $packageRoot 'Game\WFE-Libraries'
$targetWeb = Join-Path $LaunchDirectory 'ddh_web'

if (-not (Test-Path -LiteralPath $sourceWfe)) { throw "Missing package directory: $sourceWfe" }
if (Get-Process -Name War3,war3 -ErrorAction SilentlyContinue) {
    throw 'Warcraft III is running. Close the game and WFE completely before installing.'
}

$webHost = Get-Process -Name ddh_web -ErrorAction SilentlyContinue
if ($webHost) {
    Write-Host 'Stopping old ddh_web.exe...' -ForegroundColor Yellow
    $webHost | Stop-Process -Force
    Start-Sleep -Milliseconds 500
}

$launchRootFull = [IO.Path]::GetFullPath($LaunchDirectory).TrimEnd('\')
$targetWebFull = [IO.Path]::GetFullPath($targetWeb)
if (-not $targetWebFull.StartsWith(
        $launchRootFull + '\',
        [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to replace ddh_web outside LaunchDirectory: $targetWebFull"
}
if (Test-Path -LiteralPath $targetWebFull) {
    Remove-Item -LiteralPath $targetWebFull -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $WfeLibraries | Out-Null
try {
    Copy-Item -Path (Join-Path $sourceWfe '*') -Destination $WfeLibraries -Recurse -Force
}
catch {
    throw ('Install failed. Close WFE and Warcraft III, then run this installer again. ' + $_.Exception.Message)
}

$legacyHtml = Join-Path $WfeLibraries 'dss.html'
$legacyAssets = Join-Path $WfeLibraries 'dss-assets'
$legacyCore = Join-Path $WfeLibraries 'ddh_core.bin'
if (Test-Path -LiteralPath $legacyHtml) {
    Remove-Item -LiteralPath $legacyHtml -Force
}
if (Test-Path -LiteralPath $legacyAssets) {
    Remove-Item -LiteralPath $legacyAssets -Recurse -Force
}
if (Test-Path -LiteralPath $legacyCore) {
    Remove-Item -LiteralPath $legacyCore -Force
}
foreach ($name in @('ddh_web_launcher.cmd', 'ddh_web_launcher.ps1')) {
    $legacyLauncher = Join-Path $LaunchDirectory $name
    if (Test-Path -LiteralPath $legacyLauncher) {
        Remove-Item -LiteralPath $legacyLauncher -Force
    }
}

Get-ChildItem -LiteralPath $WfeLibraries -File -Recurse -ErrorAction SilentlyContinue |
    Unblock-File -ErrorAction SilentlyContinue
Write-Host ''
Write-Host 'Install complete.' -ForegroundColor Green
Write-Host "WFE libraries: $WfeLibraries"
Write-Host 'Game-side settlement UI removed.'
Write-Host 'Fully exit and restart WFE before entering a game.'
