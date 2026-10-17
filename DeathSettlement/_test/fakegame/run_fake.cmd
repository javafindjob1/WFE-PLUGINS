@echo off
rem run_fake.cmd -- start the fake target (self-test) detached, output to fake_war3.log
rem   %1 = seconds to live
rem   %2 = "weird" (different field layout) | "perf" (500 units + 256MB heap + decoys) | "big" (1200 units)
rem
rem NOTE: the fake host is deliberately named fakewar3.exe (NOT war3.exe) so it can never be
rem       confused with the real game. Use it with:  War3DeathSettlement.exe --pid <PID>
rem ASCII only on purpose; the folder path comes in via %~dp0.
cd /d "%~dp0"
if /i "%~2"=="weird"  set FAKE_LAYOUT=weird
if /i "%~2"=="perf"   set FAKE_UNITS=500
if /i "%~2"=="perf"   set FAKE_HEAP_MB=256
if /i "%~2"=="perf"   set FAKE_DECOY=1
if /i "%~2"=="big"    set FAKE_UNITS=1200
if /i "%~2"=="big"    set FAKE_HEAP_MB=512
if /i "%~2"=="big"    set FAKE_DECOY=1
if /i "%~2"=="weirdperf" set FAKE_LAYOUT=weird
if /i "%~2"=="weirdperf" set FAKE_UNITS=500
if /i "%~2"=="weirdperf" set FAKE_HEAP_MB=256
if /i "%~2"=="weirdperf" set FAKE_DECOY=1
start /b "" "%~dp0fakewar3.exe" %1 > "%~dp0fake_war3.log" 2>&1
