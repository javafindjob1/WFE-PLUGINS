param(
    [string]$WfeLibraries = 'C:\3rd\wc3gamesearcher\WFE\Application\Libraries',
    [string]$WebHostDirectory = 'C:\launch\ddh_web'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$web = Join-Path $root 'web'
$hostProject = Join-Path $root 'WebHost\DdhWebHost.csproj'
$hook = Join-Path $root '_test\hook'

Push-Location $web
try {
    npm run build
}
finally {
    Pop-Location
}

dotnet publish $hostProject -c Release -r win-x64 --self-contained true `
    -o $WebHostDirectory --nologo `
    --source 'https://api.nuget.org/v3/index.json'

$webAssets = Join-Path $WebHostDirectory 'dss-assets'
New-Item -ItemType Directory -Force -Path $webAssets | Out-Null
Copy-Item -LiteralPath (Join-Path $web 'dist\index.html') `
    -Destination (Join-Path $WebHostDirectory 'dss.html') -Force
Copy-Item -Path (Join-Path $web 'dist\dss-assets\*') `
    -Destination $webAssets -Recurse -Force

Copy-Item -LiteralPath (Join-Path $hook 'ddh.dll') -Destination $WfeLibraries -Force

Write-Host 'Vue UI deployed:' -ForegroundColor Green
Write-Host "  $(Join-Path $WebHostDirectory 'dss.html')"
Write-Host "  $webAssets"
Write-Host "  $WebHostDirectory"
Write-Host "  $(Join-Path $WfeLibraries 'ddh.dll')"
