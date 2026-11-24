# build_inject_medium.ps1 -- build a NON-elevated 32-bit injector (no requireAdministrator manifest).
# Used only for automated verification when the game runs at medium integrity.

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

$bases = @(
    'C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Tools\MSVC',
    'C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC',
    'C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Tools\MSVC',
    'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Tools\MSVC')
$all = @()
foreach ($b in $bases) { if (Test-Path $b) { $all += Get-ChildItem $b -Directory -ErrorAction SilentlyContinue } }
if ($all.Count -eq 0) { Write-Host 'MSVC not found'; exit 1 }
$ver = $all | Sort-Object Name -Descending | Select-Object -First 1
$cl = Join-Path $ver.FullName 'bin\Hostx64\x86\cl.exe'
if (-not (Test-Path $cl)) { $cl = Join-Path $ver.FullName 'bin\Hostx86\x86\cl.exe' }

$sdkInc = $null
foreach ($b in @('C:\Windows Kits\10', 'D:\Windows Kits\10', 'C:\Program Files (x86)\Windows Kits\10')) {
    $k = Join-Path $b 'Include'
    if (Test-Path $k) { $sdkInc = (Get-ChildItem $k -Directory | Sort-Object Name -Descending | Select-Object -First 1).FullName; break }
}
$sdkVer = Split-Path $sdkInc -Leaf
$sdkLib = Join-Path (Split-Path (Split-Path $sdkInc -Parent) -Parent) "Lib\$sdkVer"

$env:INCLUDE = "$($ver.FullName)\include;$sdkInc\ucrt;$sdkInc\shared;$sdkInc\um"
$env:LIB     = "$($ver.FullName)\lib\x86;$sdkLib\ucrt\x86;$sdkLib\um\x86"
$env:PATH    = (Split-Path $cl -Parent) + ';' + $env:PATH

& $cl /nologo /O2 /MD /EHsc /W3 /utf-8 /D_CRT_SECURE_NO_WARNINGS ddh_inject.cpp /link /OUT:ddh_inject_medium.exe /INCREMENTAL:NO
if ($LASTEXITCODE -ne 0) { exit 1 }
Remove-Item *.obj -ErrorAction SilentlyContinue
Get-ChildItem ddh_inject_medium.exe | Select-Object Length, Name | Format-Table -AutoSize
