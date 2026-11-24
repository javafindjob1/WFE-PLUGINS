param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $WebHostArgs
)

$ErrorActionPreference = "Stop"
$exe = "C:\launch\ddh_web\ddh_web.exe"
$workDir = "C:\launch\ddh_web"
$logDir = "C:\Users\Public\Documents\War3DeathSettlement"
$log = Join-Path $logDir "ddh-wmi-launch.txt"

try {
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    $parts = @('"' + $exe + '"')
    foreach ($arg in $WebHostArgs) {
        if ($arg -match '[\s"]') {
            $parts += '"' + ($arg -replace '"', '\"') + '"'
        }
        else {
            $parts += $arg
        }
    }
    $commandLine = $parts -join " "
    $result = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{
        CommandLine = $commandLine
        CurrentDirectory = $workDir
    }
    Add-Content -LiteralPath $log -Value ("[{0}] return={1} pid={2} args={3}" -f
        (Get-Date -Format "HH:mm:ss.fff"), $result.ReturnValue, $result.ProcessId, $commandLine)
    if ($result.ReturnValue -ne 0) { exit 2 }
}
catch {
    try {
        New-Item -ItemType Directory -Force -Path $logDir | Out-Null
        Add-Content -LiteralPath $log -Value ("[{0}] error={1}" -f
            (Get-Date -Format "HH:mm:ss.fff"), $_.Exception.Message)
    }
    catch {}
    exit 1
}
