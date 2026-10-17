@echo off
rem ---------------------------------------------------------------------------
rem build_fake.cmd -- build the fake game.dll + fake war3.exe (x86) used only by
rem this project's self-test. ASCII only on purpose (see repo notes on GBK .cmd).
rem ---------------------------------------------------------------------------
setlocal

set VCVARS=C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Auxiliary\Build\vcvarsall.bat
if not exist "%VCVARS%" (
  echo [build_fake] vcvarsall not found: %VCVARS%
  exit /b 1
)

cd /d "%~dp0"
call "%VCVARS%" x86 >nul
if errorlevel 1 ( echo [build_fake] vcvarsall failed & exit /b 1 )

echo [build_fake] compiling game.dll ...
cl /nologo /LD /O2 /MD /EHsc /W3 fake_game_dll.cpp /link /OUT:game.dll /INCREMENTAL:NO
if errorlevel 1 ( echo [build_fake] game.dll FAILED & exit /b 1 )

echo [build_fake] compiling war3.exe ...
cl /nologo /O2 /MD /EHsc /W3 fake_war3.cpp /link /OUT:war3.exe /INCREMENTAL:NO
if errorlevel 1 ( echo [build_fake] war3.exe FAILED & exit /b 1 )

del /q *.obj *.exp *.lib >nul 2>&1
echo [build_fake] done
dir /b game.dll war3.exe
exit /b 0
