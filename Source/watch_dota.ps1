$ErrorActionPreference='SilentlyContinue'
while ($true) {
  $p = Get-Process War3 | Sort-Object StartTime -Descending | Select-Object -First 1
  if ($p) {
    Start-Process -FilePath 'C:\dd\publish\War3DeathSettlement.exe' -ArgumentList @('--monitor','--hook','--pid',$p.Id,'--seconds','300') -WorkingDirectory 'C:\dd\publish'
    break
  }
  Start-Sleep -Milliseconds 100
}
