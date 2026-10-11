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

rem Give the driver a moment, then verify.
ping -n 3 127.0.0.1 >nul 2>&1

echo serial-fix-probe > COM1 2>&1
if errorlevel 1 (
  echo [serial-fix] COM1 still unavailable
  exit /b 1
)

echo [serial-fix] COM1 is ready
exit /b 0
