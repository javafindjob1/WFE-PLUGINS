@echo off
rem test-only launcher: start war3 windowed with a melee map (ASCII only, see repo notes on GBK .cmd)
cd /d C:\3rd\war5
start /b "" "C:\3rd\war5\War3.exe" -window -loadfile "%~1" >nul 2>&1
