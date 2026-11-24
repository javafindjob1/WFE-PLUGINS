$targetPid = [int]((Get-Content -LiteralPath (Join-Path $PSScriptRoot 'target_pid.txt') -Raw).Trim())
$injector = Join-Path $PSScriptRoot 'ddh_inject.exe'
& $injector $targetPid 'C:\3rd\wc3gamesearcher\WFE\Application\Libraries\ddh.dll'
exit $LASTEXITCODE
