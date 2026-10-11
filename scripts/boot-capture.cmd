@echo off
setlocal
rem Boot the VM headless and take a screenshot every N seconds.
rem Usage: boot-capture.cmd [count] [interval_seconds] [wait_before_first]
call "%~dp0..\config.cmd" 2>nul
if not defined RIG (
  echo [ERR] config.cmd missing
  exit /b 1
)

set "COUNT=%~1"
if "%COUNT%"=="" set "COUNT=8"
set "INTERVAL=%~2"
if "%INTERVAL%"=="" set "INTERVAL=12"
set "WAIT=%~3"
if "%WAIT%"=="" set "WAIT=50"

set "SHOTS=%RIG%\shots"
if not exist "%SHOTS%" mkdir "%SHOTS%"

rem VMware asks "replace or append?" if the serial log already exists; avoid that.
del /q "%RIG%\vm\serial0.log" 2>nul
del /q "%RIG%\vm\test.nvram" 2>nul

"%VMRUN%" -T ws stop "%VMX%" hard >nul 2>&1
timeout /t 5 /nobreak >nul
"%VMRUN%" -T ws start "%VMX%" nogui
if errorlevel 1 (
  echo [ERR] failed to start VM
  exit /b 1
)

timeout /t %WAIT% /nobreak >nul
for /l %%I in (1,1,%COUNT%) do (
  "%VMCLI%" "%VMX%" MKS captureScreenshot "%SHOTS%\shot%%I.png"
  timeout /t %INTERVAL% /nobreak >nul
)

echo [OK] screenshots in %SHOTS%
if exist "%RIG%\vm\serial0.log" (
  echo [OK] serial log: %RIG%\vm\serial0.log
)
exit /b 0
