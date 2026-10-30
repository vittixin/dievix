@echo off
setlocal
cd /d "%~dp0"

if not exist "..\bin\Win64" mkdir "..\bin\Win64"
if not exist "..\dcu\Win64" mkdir "..\dcu\Win64"

set DCC=C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe
set DUNITX_SRC=C:\Program Files (x86)\Embarcadero\Studio\23.0\source\DUnitX
set DELPHI_LIB=C:\Program Files (x86)\Embarcadero\Studio\23.0\lib\Win64\release
set SRC_PATHS=..\src\Engine;..\src\Domain;..\src\Database;..\src\Repositories;..\src\Services;..\src\Forms

echo Compiling DieVixTests for Win64...
"%DCC%" -B -GD -$O- DieVixTests.dpr -I"%SRC_PATHS%;%DUNITX_SRC%" -U"%SRC_PATHS%;%DUNITX_SRC%;%DELPHI_LIB%" -NS"Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;System;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win;FireDAC.Stan;FireDAC.Comp;FireDAC.Phys" -R"%SRC_PATHS%" -N0"..\dcu\Win64" -E"..\bin\Win64"

if errorlevel 1 (
    echo [ERROR] Win64 Build failed!
    exit /b 1
)

echo [SUCCESS] Win64 Build completed.
exit /b 0
