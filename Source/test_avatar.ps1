param(
    [string]$Log = "",
    [int]$WaitSeconds = 30
)

$ErrorActionPreference = "Stop"
$startTime = (Get-Date).AddMinutes(-2)
$deadline = (Get-Date).AddSeconds($WaitSeconds)

function Get-LatestLog {
    if ($Log) { return $Log }
    $dirs = @(
        (Join-Path $PSScriptRoot "publish\hook"),
        (Join-Path $PSScriptRoot "hook")
    )
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) { continue }
        $hit = Get-ChildItem $dir -Filter "ddh-*.log" -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -ge $startTime } |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

while ($true) {
    $path = Get-LatestLog
    if ($path -and (Test-Path $path)) {
        $lines = Get-Content -LiteralPath $path -Encoding UTF8
        $request = $lines | Select-String -Pattern "收到头像请求.*count=(\d+)" | Select-Object -Last 1
        $summary = $lines | Select-String -Pattern "AVATAR_SUMMARY expected=(\d+) resolved=(\d+) shown=(\d+)" | Select-Object -Last 1
        $visible = $lines | Select-String -Pattern "AVATAR_VISIBLE expected=(\d+) resolved=(\d+) visible=(\d+) shown=(\d+)" | Select-Object -Last 1
        if ($summary) {
            $expected = [int]$summary.Matches[0].Groups[1].Value
            $resolved = [int]$summary.Matches[0].Groups[2].Value
            $shown = [int]$summary.Matches[0].Groups[3].Value
            $visibleCount = if ($visible) { [int]$visible.Matches[0].Groups[3].Value } else { -1 }
            $paths = @($lines | Select-String -Pattern "面板头像：line=\d+ code=0x[0-9A-Fa-f]+ path=")
            Write-Host "log: $path"
            Write-Host "request: $($request.Line)"
            Write-Host "summary: $($summary.Line)"
            if ($visible) { Write-Host "visible: $($visible.Line)" }
            Write-Host "resolved path lines: $($paths.Count)"
            if ($expected -le 0) {
                Write-Host "FAIL: 面板图标请求 count=0（C# 没发图标，检查 SourceCode/IconBlock）"
                exit 1
            }
            if ($resolved -lt $expected) {
                Write-Host "FAIL: 有 $($expected - $resolved) 个来源图标路径未解析（看面板头像：... 行）"
                exit 1
            }
            if ($visibleCount -ge 0 -and $visibleCount -lt $expected) {
                Write-Host "FAIL: 路径已解析但只有 $visibleCount/$expected 个头像帧可见（看面板头像/帧日志）"
                exit 1
            }
            Write-Host "PASS: $resolved/$expected 个来源图标已解析并准备显示（shown=$shown）"
            exit 0
        }
    }
    if ((Get-Date) -ge $deadline) {
        Write-Host "FAIL: 等不到 AVATAR_SUMMARY。请先运行："
        Write-Host "  War3DeathSettlement.exe --monitor --hook --panel-test --seconds 20"
        Write-Host "并确认已进图、伤害钩子已连上；日志：$path"
        exit 1
    }
    Start-Sleep -Milliseconds 500
}
