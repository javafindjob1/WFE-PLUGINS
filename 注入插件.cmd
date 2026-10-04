@echo off
chcp 936 >nul
title UDamageWatcher 注入器（常驻）
echo 正在监听 war3.exe …… 每次用平台/启动器进游戏都会自动注入，这个窗口别关（可最小化）。
"%~dp0UDWInject.exe" --watch --dll "%~dp0warcraft3\UDamageWatcher.dll"
pause