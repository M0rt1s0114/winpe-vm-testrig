@echo off
setlocal
rem Assemble an ISO directory tree from the host's Windows boot files,
rem then drop in the PE's WIM as sources\boot.wim.
call "%~dp0..\config.cmd" 2>nul
if not defined RIG (
  echo [ERR] copy config.cmd.example to config.cmd and edit it first
  exit /b 1
)

set "ISO=%RIG%\iso"
set "BOOT=C:\Windows\Boot"

if exist "%ISO%" rmdir /s /q "%ISO%"
for %%D in ("boot\fonts" "efi\microsoft\boot\fonts" "efi\boot" "sources") do (
  mkdir "%ISO%\%%~D" 2>nul
)

copy /y "%BOOT%\PCAT\bootmgr"              "%ISO%\bootmgr"                        >nul
copy /y "%BOOT%\EFI\bootmgr.efi"           "%ISO%\bootmgr.efi"                    >nul
copy /y "%BOOT%\EFI\bootmgfw.efi"          "%ISO%\efi\boot\bootx64.efi"           >nul
copy /y "%BOOT%\EFI\bootmgfw.efi"          "%ISO%\efi\microsoft\boot\bootmgfw.efi" >nul
copy /y "%BOOT%\DVD\PCAT\BCD"              "%ISO%\boot\BCD"                       >nul
copy /y "%BOOT%\DVD\PCAT\boot.sdi"         "%ISO%\boot\boot.sdi"                  >nul
copy /y "%BOOT%\DVD\PCAT\etfsboot.com"     "%ISO%\boot\etfsboot.com"              >nul
copy /y "%BOOT%\DVD\EFI\BCD"               "%ISO%\efi\microsoft\boot\BCD"         >nul
copy /y "%BOOT%\DVD\EFI\boot.sdi"          "%ISO%\efi\microsoft\boot\boot.sdi"    >nul
copy /y "%BOOT%\Fonts\*.ttf"               "%ISO%\boot\fonts\"                    >nul
copy /y "%BOOT%\Fonts\*.ttf"               "%ISO%\efi\microsoft\boot\fonts\"      >nul

if not exist "%PESRC_WIM%" (
  echo [ERR] PESRC_WIM not found: %PESRC_WIM%
  exit /b 1
)
copy /y "%PESRC_WIM%" "%ISO%\sources\boot.wim" >nul

echo [OK] ISO tree prepared at %ISO%
exit /b 0
