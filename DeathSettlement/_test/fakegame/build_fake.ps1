# build_fake.ps1 -- build the fake game.dll + war3.exe (x86) used only by this project's self-test.
# ASCII ONLY on purpose (Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI/GBK).
#
# Toolchain: same approach as the repo's build_watcher.ps1 -- locate cl.exe (x86) + the Windows SDK
# and set INCLUDE/LIB/PATH directly (no vcvarsall, no cmd output capture).

[CmdletBinding()]
param(
    [string]$Cl = ''
)

$ErrorActionPreference = 'Stop'
$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Set-Location $root

function Die($m) { Write-Host $m -ForegroundColor Red; exit 1 }
function Ok($m)  { Write-Host $m -ForegroundColor Green }

function Find-Cl {
    param([string]$Explicit)
    if ($Explicit) { if (Test-Path $Explicit) { return $Explicit } else { Die "cl.exe not found: $Explicit" } }
    $bases = @(
        'C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Tools\MSVC',
        'C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC',
        'C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Tools\MSVC',
        'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Tools\MSVC',
        'D:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC',
        'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC'
    )
    $all = @()
    foreach ($b in $bases) { if (Test-Path $b) { $all += Get-ChildItem $b -Directory -ErrorAction SilentlyContinue } }
    if ($all.Count -eq 0) { Die 'MSVC (VC\Tools\MSVC) not found; pass -Cl <path to cl.exe>' }
    $ver = $all | Sort-Object Name -Descending | Select-Object -First 1
    $cl = Join-Path $ver.FullName 'bin\Hostx64\x86\cl.exe'
    if (-not (Test-Path $cl)) { $cl = Join-Path $ver.FullName 'bin\Hostx86\x86\cl.exe' }
    if (-not (Test-Path $cl)) { Die "cl.exe (x86) not found under $($ver.FullName)" }
    return $cl
}

function Find-Sdk {
    param([string]$Kind)   # 'Include' or 'Lib'
    $bases = @('C:\Windows Kits\10', 'D:\Windows Kits\10', 'C:\Program Files (x86)\Windows Kits\10')
    foreach ($b in $bases) {
        $k = Join-Path $b $Kind
        if (Test-Path $k) {
            $ver = Get-ChildItem $k -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
            if ($ver) { return $ver.FullName }
        }
    }
    Die "Windows SDK $Kind not found (looked in: $($bases -join ', '))"
}

$cl = Find-Cl -Explicit $Cl
# cl.exe lives in <MSVC>\<ver>\bin\Hostx64\x86 -> go up 4 levels to <MSVC>\<ver>
$msvcRoot = Split-Path (Split-Path (Split-Path (Split-Path $cl -Parent) -Parent) -Parent) -Parent
$sdkInc = Find-Sdk -Kind 'Include'
$sdkLib = Find-Sdk -Kind 'Lib'

Write-Host "cl.exe  : $cl"
Write-Host "MSVC    : $msvcRoot"
Write-Host "SDK Inc : $sdkInc"
Write-Host "SDK Lib : $sdkLib"

$env:INCLUDE = "$msvcRoot\include;$sdkInc\ucrt;$sdkInc\shared;$sdkInc\um"
$env:LIB     = "$msvcRoot\lib\x86;$sdkLib\ucrt\x86;$sdkLib\um\x86"
$env:PATH    = (Split-Path $cl -Parent) + ';' + $env:PATH

function Run-Cl {
    param([string[]]$Arguments)
    Write-Host ("  cl " + ($Arguments -join ' ')) -ForegroundColor DarkGray
    & $cl @Arguments
    if ($LASTEXITCODE -ne 0) { Die "cl.exe failed (exit $LASTEXITCODE)" }
}

Write-Host ''
Write-Host '== 1/2 game.dll ==' -ForegroundColor Cyan
Run-Cl @('/nologo', '/LD', '/O2', '/MD', '/EHsc', '/W3', 'fake_game_dll.cpp',
          '/link', '/OUT:game.dll', '/INCREMENTAL:NO')

Write-Host '== 2/2 fakewar3.exe ==' -ForegroundColor Cyan
Run-Cl @('/nologo', '/O2', '/MD', '/EHsc', '/W3', 'fake_war3.cpp',
          '/link', '/OUT:fakewar3.exe', '/INCREMENTAL:NO')

Remove-Item *.obj, *.exp, *.lib -ErrorAction SilentlyContinue
Ok ''
Ok '== done =='
Get-ChildItem game.dll, fakewar3.exe | Select-Object Length, Name | Format-Table -AutoSize
