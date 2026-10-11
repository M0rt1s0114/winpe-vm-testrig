@echo off
rem Sample PE-side entry script.
rem
rem Rules learned the hard way:
rem   * keep this file pure ASCII (a GBK console mangles UTF-8 comments
rem     and that can break cmd's bracket matching)
rem   * "timeout /t" does not work in WinPE; use ping or a program under test
rem   * "cls" + one screenful + wait, in a loop, so periodic screenshots
rem     always catch every stage
setlocal

call X:\TESTRIG\serial-fix.cmd

for /l %%R in (1,1,4) do (
  cls
  echo ===== stage A =====
  echo arch=%PROCESSOR_ARCHITECTURE%  systemroot=%SystemRoot%
  dir X:\TESTRIG\ 2>&1
  echo hello-from-guest > COM1 2>&1
  echo serial-probe-done
  call :delay

  cls
  echo ===== stage B =====
  reg query HKLM\HARDWARE\DEVICEMAP\SERIALCOMM 2>&1
  call :delay
)

cls
echo ==== done ====
exit /b 0

:delay
ping -n 13 127.0.0.1 >nul 2>&1
exit /b 0
