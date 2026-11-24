# _selftest.ps1 -- build & run the two console self-tests against ddh.cpp
$ErrorActionPreference = 'Stop'
$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Set-Location $root

function Die($m) { Write-Host $m -ForegroundColor Red; exit 1 }
function Find-Cl {
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
    return @{ Cl = $cl; Root = $ver.FullName }
}
function Find-Sdk([string]$Kind) {
    foreach ($b in @('C:\Windows Kits\10', 'D:\Windows Kits\10', 'C:\Program Files (x86)\Windows Kits\10')) {
        $k = Join-Path $b $Kind
        if (Test-Path $k) {
            $ver = Get-ChildItem $k -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
            if ($ver) { return $ver.FullName }
        }
    }
    Die "Windows SDK $Kind not found"
}

$msvc = Find-Cl
$sdkInc = Find-Sdk 'Include'
$sdkLib = Find-Sdk 'Lib'
$env:INCLUDE = "$($msvc.Root)\include;$sdkInc\ucrt;$sdkInc\shared;$sdkInc\um"
$env:LIB     = "$($msvc.Root)\lib\x86;$sdkLib\ucrt\x86;$sdkLib\um\x86"
$env:PATH    = (Split-Path $msvc.Cl -Parent) + ';' + $env:PATH

foreach ($def in @('DDH_MSG_TEST', 'DDH_CHILDSUM_TEST')) {
    Write-Host "== $def ==" -ForegroundColor Cyan
    & $msvc.Cl /nologo /O2 /MD /EHsc /W3 /utf-8 /D_CRT_SECURE_NO_WARNINGS "/D$def" ddh.cpp /link /OUT:"t_$def.exe" /INCREMENTAL:NO | Out-Null
    if ($LASTEXITCODE -ne 0) { Die "$def build failed ($LASTEXITCODE)" }
    & ".\t_$def.exe" | Select-Object -Last 12
    Write-Host "exit=$LASTEXITCODE" -ForegroundColor Yellow
    Remove-Item "t_$def.exe", "ddh.obj" -ErrorAction SilentlyContinue
}
Remove-Item *.obj, *.exp, *.lib -ErrorAction SilentlyContinue
