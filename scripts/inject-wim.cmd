@echo off
setlocal
rem Copy the source WIM, apply the commands in wimupdate.txt, and put the
rem result into the ISO tree. The original WIM is never modified.
call "%~dp0..\config.cmd" 2>nul
if not defined RIG (
  echo [ERR] config.cmd missing
  exit /b 1
)

set "WORK=%RIG%\build\test.wim"
set "CMDFILE=%RIG%\wimupdate.txt"

if not exist "%CMDFILE%" (
  echo [ERR] %CMDFILE% not found
  exit /b 1
)

copy /y "%PESRC_WIM%" "%WORK%" >nul
"%WIMLIB%" update "%WORK%" 1 < "%CMDFILE%"
if errorlevel 1 (
  echo [ERR] wimlib update failed
  exit /b 1
)

copy /y "%WORK%" "%RIG%\iso\sources\boot.wim" >nul
echo [OK] injected and staged into ISO tree
exit /b 0
