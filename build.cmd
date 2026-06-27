@echo off
REM ===========================================================================
REM  build.cmd  --  compile pastethrough.ahk -> pastethrough.exe
REM
REM  Requires AutoHotkey v2 installed (Ahk2Exe ships with it).
REM  Run from a normal cmd.exe or PowerShell prompt:
REM      build.cmd
REM
REM  NOTE for Git Bash users: do NOT run this through sh.exe with `/in` style
REM  args directly -- MSYS path-translation mangles `/in` into a Windows path
REM  and Ahk2Exe throws a popup. If you must build from Git Bash, prefix with:
REM      MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" build.cmd
REM ===========================================================================
setlocal

set "AHK2EXE=C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
set "BASE=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"

if not exist "%AHK2EXE%" (
  echo [build] Ahk2Exe not found at:
  echo        %AHK2EXE%
  echo        Install AutoHotkey v2 from https://www.autohotkey.com/ first.
  exit /b 1
)
if not exist "%BASE%" (
  echo [build] AutoHotkey v2 base exe not found at:
  echo        %BASE%
  echo        Install AutoHotkey v2 first.
  exit /b 1
)
if not exist pastethrough.ahk (
  echo [build] pastethrough.ahk not found in current dir. cd into the PasteThrough folder.
  exit /b 1
)

echo [build] Compiling pastethrough.ahk -^> pastethrough.exe ...
"%AHK2EXE%" /in pastethrough.ahk /out pastethrough.exe /base "%BASE%"
if errorlevel 1 (
  echo [build] Compile FAILED.
  exit /b 1
)
echo [build] OK: pastethrough.exe
endlocal
