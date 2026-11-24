$target = Get-Process War3 -ErrorAction SilentlyContinue |
    Where-Object { $_.Threads.Count -gt 0 } |
    Select-Object -First 1
if ($target) { Stop-Process -Id $target.Id -Force }
