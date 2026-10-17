@echo off
rem ---------------------------------------------------------------------------
rem check.cmd -- one-click self-check / acceptance helper for War3DeathSettlement
rem   1) offline self-test (needs no game)
rem   2) live diagnostic against a running war3.exe (read-only)
rem Reports land next to the exe:  logs\selftest.txt  and  logs\probe-*.txt
rem ASCII only on purpose (cmd reads .cmd in the OEM code page).
rem ---------------------------------------------------------------------------
setlocal
cd /d "%~dp0"

echo ============================================================
echo  War3DeathSettlement - one-click check
echo ============================================================
echo.
echo [1/3] offline self-test ...
echo ------------------------------------------------------------
"%~dp0War3DeathSettlement.exe" --selftest
echo.
echo [2/3] live diagnostic (works only while the game is running) ...
echo ------------------------------------------------------------
"%~dp0War3DeathSettlement.exe" --probe --deep
echo.
echo [3/3] opening the log folder ...
echo ------------------------------------------------------------
start "" "%~dp0logs"
echo.
echo Done. If something looks wrong, send the newest logs\probe-*.txt.
pause
