@echo off
setlocal
cd /d "%~dp0"

if not exist "..\bin" mkdir "..\bin"
if not exist "..\dcu" mkdir "..\dcu"

set DCC=C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc32.exe
set DUNITX_SRC=C:\Program Files (x86)\Embarcadero\Studio\23.0\source\DUnitX
set DELPHI_LIB=C:\Program Files (x86)\Embarcadero\Studio\23.0\lib\Win32\release

echo Compiling DieVixTests...
"%DCC%" -B -GD -$O- DieVixTests.dpr -I"..\src\Engine;%DUNITX_SRC%" -U"..\src\Engine;%DUNITX_SRC%;%DELPHI_LIB%" -NS"System;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win" -N0"..\dcu" -E"..\bin"

if errorlevel 1 (
    echo [ERROR] Build failed!
    exit /b 1
)

echo [SUCCESS] Build completed. Running tests...
echo.
"..\bin\DieVixTests.exe"
exit /b %errorlevel%
