# unblock.ps1 -- remove Mark-of-the-Web (the NTFS "Zone.Identifier" stream).
#
# Why: a file that carries Zone.Identifier is treated as "downloaded from the
# Internet". For an unsigned exe that means two extra confirmations before it runs:
#   1) SmartScreen  "Windows protected your PC"
#   2) Shell       "The publisher could not be verified. Are you sure you want to run?"
# Removing the stream makes both disappear. (Signing the exe also works, and is the
# long-term fix; this script is the zero-cost one.)
#
# Facts worth knowing:
#   * MOTW is an NTFS alternate data stream, not a file attribute; FAT/exFAT cannot hold it.
#   * Copy-Item / drag-copy PRESERVES it, so unblock at the FINAL location.
#   * Renaming does NOT remove it; rebuilding the exe does (it is a new file).
#   * It is added by: browser downloads, Outlook/Attachment Manager, most IM apps
#     (WeChat/QQ/TIM), network shares, and extracting a zip whose entries carry it.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\unblock.ps1
#   powershell -ExecutionPolicy Bypass -File tools\unblock.ps1 -Path publish
#   powershell -ExecutionPolicy Bypass -File tools\unblock.ps1 -Path publish\War3DeathSettlement.exe
#
# ASCII only (Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI).

[CmdletBinding()]
param(
    [string]$Path = 'publish',
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Path)) {
    Write-Host "path not found: $Path" -ForegroundColor Red
    exit 1
}

$item = Get-Item $Path
if ($item.PSIsContainer) {
    $files = @(Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue)
} else {
    $files = @($item)
}

$blocked = 0
$cleared = 0

foreach ($f in $files) {
    $streams = @(Get-Item $f.FullName -Stream * -ErrorAction SilentlyContinue |
                 Select-Object -ExpandProperty Stream)
    if ($streams -notcontains 'Zone.Identifier') { continue }

    $blocked++
    $zone = ''
    try {
        $zone = (Get-Content $f.FullName -Stream Zone.Identifier -ErrorAction SilentlyContinue |
                 Where-Object { $_ -match '^ZoneId=' }) -join ' '
    } catch { }

    try {
        Unblock-File -Path $f.FullName
        $cleared++
        if (-not $Quiet) { Write-Host ("  cleared  {0}  {1}" -f $zone, $f.FullName) -ForegroundColor Yellow }
    } catch {
        Write-Host ("  FAILED   {0}  {1}" -f $f.FullName, $_.Exception.Message) -ForegroundColor Red
    }
}

if ($blocked -eq 0) {
    if (-not $Quiet) { Write-Host "no Zone.Identifier found (nothing to do) - $Path" -ForegroundColor Green }
} else {
    Write-Host ("blocked {0} file(s), cleared {1} - {2}" -f $blocked, $cleared, $Path) -ForegroundColor Green
}

exit 0
