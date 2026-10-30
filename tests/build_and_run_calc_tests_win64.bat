@echo off
setlocal
cd /d "%~dp0"

if not exist "..\bin\Win64" mkdir "..\bin\Win64"
if not exist "..\dcu\Win64" mkdir "..\dcu\Win64"

set DCC=C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe
set DUNITX_SRC=C:\Program Files (x86)\Embarcadero\Studio\23.0\source\DUnitX
set DELPHI_LIB=C:\Program Files (x86)\Embarcadero\Studio\23.0\lib\Win64\release
set SRC_PATHS=..\src\Engine

echo Compiling DieVixCalculationTestsWin64 (Win64)...
"%DCC%" -B -GD -$O- DieVixCalculationTestsWin64.dpr -I"%SRC_PATHS%;%DUNITX_SRC%" -U"%SRC_PATHS%;%DUNITX_SRC%;%DELPHI_LIB%" -NS"System;Winapi;System.Win" -N0"..\dcu\Win64" -E"..\bin\Win64"

if errorlevel 1 (
    echo [ERROR] Build failed!
    exit /b 1
)

echo [SUCCESS] Build completed. Running calculation tests (Win64)...
echo.
"..\bin\Win64\DieVixCalculationTestsWin64.exe"
exit /b %errorlevel%
