# build_realattach.ps1 -- build the tiny host that loads the REAL game.dll.
# ASCII only (Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI).
# Reuses the same toolchain discovery as build_fake.ps1.

[CmdletBinding()]
param([string]$Cl = '')

$ErrorActionPreference = 'Stop'
$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Set-Location $root

function Die($m) { Write-Host $m -ForegroundColor Red; exit 1 }
function Find-Cl {
    param([string]$Explicit)
    if ($Explicit) { if (Test-Path $Explicit) { return $Explicit } else { Die "cl.exe not found: $Explicit" } }
    $bases = @(
        'C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Tools\MSVC',
        'C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC',
        'C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Tools\MSVC',
        'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Tools\MSVC'
    )
    $all = @()
    foreach ($b in $bases) { if (Test-Path $b) { $all += Get-ChildItem $b -Directory -ErrorAction SilentlyContinue } }
    if ($all.Count -eq 0) { Die 'MSVC not found' }
    $ver = $all | Sort-Object Name -Descending | Select-Object -First 1
    $cl = Join-Path $ver.FullName 'bin\Hostx64\x86\cl.exe'
    if (-not (Test-Path $cl)) { $cl = Join-Path $ver.FullName 'bin\Hostx86\x86\cl.exe' }
    if (-not (Test-Path $cl)) { Die "cl.exe (x86) not found under $($ver.FullName)" }
    return $cl
}
function Find-Sdk {
    param([string]$Kind)
    foreach ($b in @('C:\Windows Kits\10', 'D:\Windows Kits\10', 'C:\Program Files (x86)\Windows Kits\10')) {
        $k = Join-Path $b $Kind
        if (Test-Path $k) {
            $ver = Get-ChildItem $k -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
            if ($ver) { return $ver.FullName }
        }
    }
    Die "Windows SDK $Kind not found"
}

$cl = Find-Cl -Explicit $Cl
$msvcRoot = Split-Path (Split-Path (Split-Path (Split-Path $cl -Parent) -Parent) -Parent) -Parent
$sdkInc = Find-Sdk -Kind 'Include'
$sdkLib = Find-Sdk -Kind 'Lib'
$env:INCLUDE = "$msvcRoot\include;$sdkInc\ucrt;$sdkInc\shared;$sdkInc\um"
$env:LIB     = "$msvcRoot\lib\x86;$sdkLib\ucrt\x86;$sdkLib\um\x86"
$env:PATH    = (Split-Path $cl -Parent) + ';' + $env:PATH

Write-Host "cl: $cl" -ForegroundColor DarkGray
& $cl /nologo /O2 /MD /EHsc /W3 realattach_host.cpp /link /OUT:realattach_host.exe /INCREMENTAL:NO
if ($LASTEXITCODE -ne 0) { Die "build failed ($LASTEXITCODE)" }
Remove-Item *.obj, *.exp, *.lib -ErrorAction SilentlyContinue
Write-Host '== done ==' -ForegroundColor Green
Get-ChildItem realattach_host.exe | Select-Object Length, Name | Format-Table -AutoSize
