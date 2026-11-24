@echo off
setlocal EnableExtensions EnableDelayedExpansion
if "%~1"=="" exit /b 1
start "" /D "C:\launch\ddh_web" "C:\launch\ddh_web\ddh_web.exe" %*
set "DDH_MARKER="
:parse_marker
if "%~1"=="" goto save_marker
if /I "%~1"=="--ddh-marker" (
    set "DDH_MARKER=%~2"
    shift
    shift
    goto save_marker
)
shift
goto parse_marker
:save_marker
if defined DDH_MARKER (
    if not exist "C:\Users\Public\Documents\War3DeathSettlement" mkdir "C:\Users\Public\Documents\War3DeathSettlement" >nul 2>&1
    >"C:\Users\Public\Documents\War3DeathSettlement\ddh-button-seq.txt" <nul set /p "=!DDH_MARKER!"
)
endlocal
