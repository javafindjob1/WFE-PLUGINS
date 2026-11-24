@echo off
chcp 65001 >nul
title War3DeathSettlement 自动注入（常驻监视）
cd /d "%~dp0"

rem 每次 war3.exe 启动，等 Game.dll 就绪后自动注入 ddh.dll
rem 双击一次即可；关闭窗口即停止监视。
rem 想换 DLL：改下面 DLL= 这行（默认发行包 v18；测试版在 _test\hook\ddh.dll）

set "DLL=%~dp0release\War3DeathSettlement_v1.3.2_20261105\hook\ddh.dll"
if not exist "%DLL%" set "DLL=%~dp0_test\hook\ddh.dll"
if not exist "%DLL%" (
    echo [错误] 找不到 ddh.dll
    pause
    exit /b 1
)

echo 监视中：war3.exe 一启动就会自动注入
echo DLL = %DLL%
echo.
"%~dp0..\..\UDWInject.exe" --watch --dll "%DLL%"
echo.
echo 注入器已退出
pause
