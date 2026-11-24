# Build and run the settlement registry regression test.
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

function Die([string]$message)
{
    Write-Host $message -ForegroundColor Red
    exit 1
}

function Find-Cl
{
    $bases = @(
        'C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Tools\MSVC',
        'C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC',
        'C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Tools\MSVC',
        'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Tools\MSVC'
    )
    $all = @()
    foreach ($base in $bases)
    {
        if (Test-Path $base) { $all += Get-ChildItem $base -Directory }
    }
    if ($all.Count -eq 0) { Die 'MSVC not found' }

    $version = $all | Sort-Object Name -Descending | Select-Object -First 1
    $cl = Join-Path $version.FullName 'bin\Hostx64\x86\cl.exe'
    if (-not (Test-Path $cl)) { $cl = Join-Path $version.FullName 'bin\Hostx86\x86\cl.exe' }
    if (-not (Test-Path $cl)) { Die 'x86 cl.exe not found' }
    return @{ Cl = $cl; Root = $version.FullName }
}

function Find-Sdk([string]$kind)
{
    foreach ($base in @('C:\Windows Kits\10', 'D:\Windows Kits\10', 'C:\Program Files (x86)\Windows Kits\10'))
    {
        $dir = Join-Path $base $kind
        if (-not (Test-Path $dir)) { continue }
        $version = Get-ChildItem $dir -Directory | Sort-Object Name -Descending | Select-Object -First 1
        if ($version) { return $version.FullName }
    }
    Die "Windows SDK $kind not found"
}

$msvc = Find-Cl
$sdkInc = Find-Sdk 'Include'
$sdkLib = Find-Sdk 'Lib'
$env:INCLUDE = "$($msvc.Root)\include;$sdkInc\ucrt;$sdkInc\shared;$sdkInc\um"
$env:LIB = "$($msvc.Root)\lib\x86;$sdkLib\ucrt\x86;$sdkLib\um\x86"
$env:PATH = (Split-Path $msvc.Cl -Parent) + ';' + $env:PATH

$exe = 't_settle_registry_test.exe'
& $msvc.Cl /nologo /O2 /MD /EHsc /W3 /utf-8 /D_CRT_SECURE_NO_WARNINGS `
    settle_registry_test.cpp /link /OUT:$exe /INCREMENTAL:NO
if ($LASTEXITCODE -ne 0) { Die "settlement registry test build failed ($LASTEXITCODE)" }

try
{
    & ".\$exe"
    if ($LASTEXITCODE -ne 0) { Die "settlement registry test failed ($LASTEXITCODE)" }
}
finally
{
    Remove-Item $exe, 'settle_registry_test.obj' -ErrorAction SilentlyContinue
}
