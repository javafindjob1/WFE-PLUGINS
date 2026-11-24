@echo off
cd /d "%~dp0"
echo ============================================
echo   War3DeathSettlement - avatar auto test
echo   (game must already be running and in map)
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_avatar_test.ps1" -Seconds 30
echo.
echo Test finished. Copy the output above if it failed.
pause
