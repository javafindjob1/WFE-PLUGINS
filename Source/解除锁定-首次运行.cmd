@echo off
rem Remove the "downloaded from the Internet" mark (Zone.Identifier) from every file
rem in this folder, so Windows SmartScreen stops showing "Windows protected your PC".
rem Run this once after copying/unzipping the tool to a new machine.
setlocal
echo Unblocking: "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Get-ChildItem -LiteralPath '%~dp0' -Recurse -File -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue"
if errorlevel 1 (
  echo Failed. Try running this file as administrator, or unblock the exe manually:
  echo   right-click War3DeathSettlement.exe - Properties - Unblock - OK
) else (
  echo Done. You can delete this .cmd file.
)
pause
