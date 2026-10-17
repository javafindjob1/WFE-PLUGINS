# watch_probe.ps1 -- ASCII ONLY on purpose.
# Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI/GBK, so this file must contain no
# non-ASCII characters. Paths (which do contain CJK) are passed in as arguments.
#
# Waits for a running war3.exe, then runs the read-only live diagnostic against it and
# writes the report + a small status file.

param(
    [Parameter(Mandatory = $true)][string]$Exe,
    [Parameter(Mandatory = $true)][string]$Dir,
    [int]$Minutes = 60,
    [int]$ProbeWaitSeconds = 10
)

$status = Join-Path $Dir 'watch_status.txt'
$latest = Join-Path $Dir 'probe_live.txt'
$deadline = (Get-Date).AddMinutes($Minutes)
$attempt = 0

function Set-Status([string]$text) {
    try { Set-Content -Path $status -Value $text -Encoding UTF8 } catch { }
}

Set-Status ("start " + (Get-Date -Format 'HH:mm:ss'))

while ((Get-Date) -lt $deadline) {
    $p = @(Get-Process | Where-Object { $_.ProcessName -match '(?i)^war3$|^dzwar3$|^Warcraft' })
    if ($p.Count -eq 0) {
        Set-Status ((Get-Date -Format 'HH:mm:ss') + " game=no attempt=$attempt")
        Start-Sleep -Seconds 10
        continue
    }

    $attempt++
    $pidList = ($p | ForEach-Object { "$($_.ProcessName)#$($_.Id)" }) -join ','
    Set-Status ((Get-Date -Format 'HH:mm:ss') + " game=yes $pidList attempt=$attempt probing...")
    Start-Sleep -Seconds $ProbeWaitSeconds

    $out = & $Exe --probe --deep 2>&1 | Out-String
    $report = Join-Path $Dir ("probe_live_" + (Get-Date -Format 'HHmmss') + ".txt")
    try {
        Set-Content -Path $report -Value $out -Encoding UTF8
        Set-Content -Path $latest -Value $out -Encoding UTF8
    } catch { }

    $units = '?'
    if ($out -match '(\d+) ') { }
    $m = [regex]::Match($out, 'units=(\d+)')
    if ($m.Success) { $units = $m.Groups[1].Value }
    $ctx = '?'
    $m2 = [regex]::Match($out, 'ctx\s*=\s*(0x[0-9A-Fa-f]{8})')
    if ($m2.Success) { $ctx = $m2.Groups[1].Value }

    # the report prints:  "用时 N ms，扫描 M MB，发现单位 K 个"  -- find the number before the last marker
    $m3 = [regex]::Match($out, '([0-9]+)\s*[\u4e2a]')
    if ($m3.Success -and $m3.Groups[1].Value -ne '0') { $units = $m3.Groups[1].Value }

    Set-Status ((Get-Date -Format 'HH:mm:ss') + " game=yes $pidList attempt=$attempt ctx=$ctx units=$units report=$report")

    if ($units -ne '?' -and [int]$units -gt 0) { break }
    Start-Sleep -Seconds 20
}

Set-Status ((Get-Content $status -Raw) + "`nDONE " + (Get-Date -Format 'HH:mm:ss'))
