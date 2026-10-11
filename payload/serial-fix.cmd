@echo off
rem Make VMware's virtual serial port show up as COM1 inside WinPE.
rem Without this, "echo x > COM1" fails with
rem   The system cannot find the file specified.
rem even though the ACPI UART device and the Serial service are present.
setlocal

rem Only touch the device parameters if the device exists.
reg query "HKLM\SYSTEM\CurrentControlSet\Enum\ACPI\PNP0501\1" >nul 2>&1
if errorlevel 1 (
  echo [serial-fix] no ACPI\PNP0501 device, nothing to do
  exit /b 1
)

reg add "HKLM\SYSTEM\CurrentControlSet\Enum\ACPI\PNP0501\1\Device Parameters" ^
  /v PortName /t REG_SZ /d COM1 /f >nul 2>&1

pnputil /restart-device "ACPI\PNP0501\1" >nul 2>&1

rem The COM1 DOS name appears asynchronously after the restart, so wait for it
rem to show up in the SERIALCOMM map. Writing "> COM1" before that does not
rem fail loudly: cmd silently creates a *file* called COM1 instead, which
rem swallows output instead of erroring.
set /a TRIES=0

:wait_serial
reg query HKLM\HARDWARE\DEVICEMAP\SERIALCOMM 2>nul | findstr /i /c:"COM1" >nul
if not errorlevel 1 (
  goto :warmup
)
set /a TRIES+=1
if %TRIES% GEQ 30 (
  echo [serial-fix] COM1 did not appear
  exit /b 1
)
ping -n 2 127.0.0.1 >nul 2>&1
goto :wait_serial

:warmup
rem VMware opens the serial output file lazily, and the first guest write has
rem been observed to disappear. Burn a few throwaways so the caller's real
rem output is not what gets lost.
echo serial-warmup > COM1 2>&1
ping -n 3 127.0.0.1 >nul 2>&1
echo serial-warmup > COM1 2>&1
ping -n 3 127.0.0.1 >nul 2>&1
echo [serial-fix] COM1 is ready
exit /b 0
