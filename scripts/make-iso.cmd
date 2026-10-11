@echo off
setlocal
rem Build a BIOS+UEFI bootable ISO from %RIG%\iso.
call "%~dp0..\config.cmd" 2>nul
if not defined RIG (
  echo [ERR] config.cmd missing
  exit /b 1
)

set "EFISYS=C:\Windows\Boot\DVD\EFI\en-US\efisys.bin"
set "OUT=%RIG%\test.iso"

if not exist "%RIG%\iso\sources\boot.wim" (
  echo [ERR] run prepare-iso.cmd first
  exit /b 1
)

"%OSCDIMG%" -bootdata:2#p0,e,b"%RIG%\iso\boot\etfsboot.com"#pEF,e,b"%EFISYS%" ^
  -h -m -u2 -udfver102 -lPETEST "%RIG%\iso" "%OUT%"
if errorlevel 1 (
  echo [ERR] oscdimg failed
  exit /b 1
)

echo [OK] %OUT%
exit /b 0
