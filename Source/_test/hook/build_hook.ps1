# build_hook.ps1 -- build the injected hook DLL (32-bit) and its injector.
# ASCII only (Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI).

[CmdletBinding()]
param()

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
    if (-not (Test-Path $cl)) { Die "cl.exe (x86) not found under $($ver.FullName)" }
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

# SDK version dir is also needed to locate mt.exe (embed the injector manifest).
$sdkVer = Split-Path $sdkInc -Leaf

Write-Host "cl: $($msvc.Cl)" -ForegroundColor DarkGray

Write-Host '== 1/2 combined ddh.dll ==' -ForegroundColor Cyan
& $msvc.Cl /nologo /LD /O2 /MD /EHsc /W3 /utf-8 /D_CRT_SECURE_NO_WARNINGS /I"sqlite" /I"third_party\detours" /DSQLITE_THREADSAFE=1 /DSQLITE_OMIT_LOAD_EXTENSION ddh.cpp "third_party\detours\detours.cpp" "third_party\detours\modules.cpp" "third_party\detours\disasm.cpp" "third_party\detours\image.cpp" "third_party\detours\creatwth.cpp" "third_party\detours\disolx86.cpp" "third_party\detours\disolx64.cpp" "third_party\detours\disolia64.cpp" "third_party\detours\disolarm.cpp" "third_party\detours\disolarm64.cpp" "sqlite\sqlite3.c" /link /OUT:ddh.dll /INCREMENTAL:NO user32.lib shell32.lib ole32.lib uuid.lib
if ($LASTEXITCODE -ne 0) { Die "combined ddh.dll build failed ($LASTEXITCODE)" }

$panelBlp = Join-Path $root 'assets\ddh_panel.blp'
if (Test-Path $panelBlp) {
    Copy-Item -LiteralPath $panelBlp -Destination 'C:\3rd\war5\UI\ddh_panel.blp' -Force
}

Write-Host '== 2/2 ddh_inject.exe ==' -ForegroundColor Cyan
& $msvc.Cl /nologo /O2 /MD /EHsc /W3 /utf-8 /D_CRT_SECURE_NO_WARNINGS ddh_inject.cpp /link /OUT:ddh_inject.exe /INCREMENTAL:NO
if ($LASTEXITCODE -ne 0) { Die "ddh_inject.exe build failed ($LASTEXITCODE)" }

# Embed ddh_inject.manifest with mt.exe: requireAdministrator makes Explorer show the UAC shield
# and makes a direct double-click elevate. Do NOT use /MANIFESTUAC from PowerShell: its quoting
# is easy to break, and the manifest then silently stays out of the exe.
$mt = $null
foreach ($b in @('C:\Windows Kits\10', 'D:\Windows Kits\10', 'C:\Program Files (x86)\Windows Kits\10')) {
    if (-not (Test-Path $b)) { continue }
    $cand = Join-Path $b "bin\$sdkVer\x86\mt.exe"
    if (Test-Path $cand) { $mt = $cand; break }
}
if (-not $mt) { Die 'mt.exe not found (Windows SDK)' }
& $mt -nologo -manifest ddh_inject.manifest -outputresource:'ddh_inject.exe;#1'
if ($LASTEXITCODE -ne 0) { Die "ddh_inject.exe manifest embed failed ($LASTEXITCODE)" }

Remove-Item *.obj, *.exp, *.lib -ErrorAction SilentlyContinue
Write-Host '== done ==' -ForegroundColor Green
Get-ChildItem ddh.dll, ddh_inject.exe | Select-Object Length, Name | Format-Table -AutoSize
