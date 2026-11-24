# deploy.ps1 -- build Release, copy the app files into publish\, clear Mark-of-the-Web.
#
# This exists because the manual flow is easy to get wrong: it is possible to rebuild,
# forget to copy the new .dll, and then spend an hour debugging behaviour that the old
# binary still has (the build stamp in the title bar comes from the .dll's write time,
# so it is the quickest way to confirm what you are actually running).
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\deploy.ps1
#   powershell -ExecutionPolicy Bypass -File tools\deploy.ps1 -NoBuild
#
# ASCII only (Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI).

[CmdletBinding()]
param(
    [string]$Configuration = 'Release',
    [switch]$NoBuild
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Push-Location $root
try {
    if (-not $NoBuild) {
        Write-Host "== build ($Configuration) ==" -ForegroundColor Cyan
        dotnet build -c $Configuration --nologo -v q
        if ($LASTEXITCODE -ne 0) { throw "build failed ($LASTEXITCODE)" }
    }

    $src = Join-Path $root "bin\$Configuration\net10.0-windows"
    $dst = Join-Path $root 'publish'
    if (-not (Test-Path $src)) { throw "build output not found: $src" }

    Write-Host "== copy to publish ==" -ForegroundColor Cyan
    $files = @(
        'War3DeathSettlement.exe',
        'War3DeathSettlement.dll',
        'War3DeathSettlement.deps.json',
        'War3DeathSettlement.runtimeconfig.json'
    )
    foreach ($f in $files) {
        $s = Join-Path $src $f
        if (Test-Path $s) { Copy-Item $s (Join-Path $dst $f) -Force }
    }

    Write-Host "== clear Mark-of-the-Web ==" -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot 'unblock.ps1') -Path $dst

    $exe = Join-Path $dst 'War3DeathSettlement.exe'
    $stamp = (Get-Item $exe).LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
    $hasAdmin = $false
    try {
        $bytes = [IO.File]::ReadAllBytes($exe)
        $ascii = [Text.Encoding]::ASCII.GetString($bytes)
        $hasAdmin = $ascii.Contains('requireAdministrator')
    } catch { }

    Write-Host ""
    Write-Host "publish\War3DeathSettlement.exe" -ForegroundColor Green
    Write-Host ("  build stamp : {0}   (title bar shows this)" -f $stamp)
    Write-Host ("  elevation   : {0}" -f $(if ($hasAdmin) { 'requireAdministrator (UAC shield)' } else { 'asInvoker' }))
} finally {
    Pop-Location
}
