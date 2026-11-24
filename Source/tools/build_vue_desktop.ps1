param(
    [string]$PublishDirectory,
    [string]$WebHostDirectory = 'C:\launch\ddh_web'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (-not $PublishDirectory) {
    $PublishDirectory = Join-Path $root 'publish_vue'
}

Push-Location (Join-Path $root 'web')
try {
    npm run build
}
finally {
    Pop-Location
}

dotnet publish (Join-Path $root 'DesktopHost\War3DeathSettlement.Desktop.csproj') `
    -c Release -r win-x64 --self-contained true `
    -o $PublishDirectory `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:EnableCompressionInSingleFile=true `
    --nologo `
    --source 'https://api.nuget.org/v3/index.json'

$desktopExe = Join-Path $PublishDirectory 'War3DeathSettlement.exe'
$releaseExe = Join-Path $root 'publish\War3DeathSettlement.exe'
if (Test-Path -LiteralPath $releaseExe) {
    $backup = Join-Path $root (
        'publish\War3DeathSettlement.winforms-' +
        (Get-Date -Format 'yyyyMMdd-HHmmss') + '.exe'
    )
    Copy-Item -LiteralPath $releaseExe -Destination $backup
}
Copy-Item -LiteralPath $desktopExe -Destination $releaseExe -Force

$assets = Join-Path $WebHostDirectory 'dss-assets'
New-Item -ItemType Directory -Force -Path $assets | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'web\dist\index.html') `
    -Destination (Join-Path $WebHostDirectory 'dss.html') -Force
Copy-Item -Path (Join-Path $root 'web\dist\dss-assets\*') `
    -Destination $assets -Recurse -Force

Write-Host 'Vue desktop built and deployed:' -ForegroundColor Green
Write-Host "  $desktopExe"
Write-Host "  $releaseExe"
Write-Host "  $(Join-Path $WebHostDirectory 'dss.html')"
