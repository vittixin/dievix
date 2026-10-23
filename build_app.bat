@echo off
setlocal
cd /d "%~dp0"

if not exist "bin" mkdir "bin"
if not exist "dcu" mkdir "dcu"

set DCC=C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc32.exe
set DELPHI_LIB=C:\Program Files (x86)\Embarcadero\Studio\23.0\lib\Win32\release
set SRC_PATHS=src\Engine;src\Domain;src\Database;src\Repositories;src\Services;src\Forms

echo Compiling DieVix.exe...
"%DCC%" -B -GD -$O- DieVix.dpr -I"%SRC_PATHS%" -U"%SRC_PATHS%;%DELPHI_LIB%" -NS"Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;System;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win;FireDAC.Stan;FireDAC.Comp;FireDAC.Phys" -R"%SRC_PATHS%" -N0"dcu" -E"bin"

if errorlevel 1 (
    echo [ERROR] DieVix.exe build failed!
    exit /b 1
)

copy /y DieVix.ini bin\DieVix.ini >nul
if not exist "bin\migrations" mkdir "bin\migrations"
copy /y migrations\*.sql bin\migrations\ >nul
echo [SUCCESS] DieVix.exe build completed successfully!
exit /b 0
