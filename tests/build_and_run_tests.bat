@echo off
setlocal
cd /d "%~dp0"

if not exist "..\bin" mkdir "..\bin"
if not exist "..\dcu" mkdir "..\dcu"

set DCC=C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc32.exe
set DUNITX_SRC=C:\Program Files (x86)\Embarcadero\Studio\23.0\source\DUnitX
set DELPHI_LIB=C:\Program Files (x86)\Embarcadero\Studio\23.0\lib\Win32\release
set VITTIX_REPORT=..\..\VittixReport\source;..\..\VittixReport\source\ThirdParty\QRCodeGenLib\src\QRCodeGen;..\..\VittixReport\source\ThirdParty\QRCodeGenLib\src\Interfaces;..\..\VittixReport\source\ThirdParty\QRCodeGenLib\src\Utils;..\..\VittixReport\source\ThirdParty\QRCodeGenLib\src\Include
set SRC_PATHS=..\src\Engine;..\src\Domain;..\src\Database;..\src\Repositories;..\src\Services;..\src\Forms;%VITTIX_REPORT%

echo Compiling DieVixTests...
"%DCC%" -B -GD -$O- DieVixTests.dpr -I"%SRC_PATHS%;%DUNITX_SRC%" -U"%SRC_PATHS%;%DUNITX_SRC%;%DELPHI_LIB%" -NS"Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;System;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win;FireDAC.Stan;FireDAC.Comp;FireDAC.Phys" -R"%SRC_PATHS%" -N0"..\dcu" -E"..\bin"

if errorlevel 1 (
    echo [ERROR] Build failed!
    exit /b 1
)

echo [SUCCESS] Build completed. Running tests...
if not exist "..\bin\reports" mkdir "..\bin\reports"
copy /y ..\reports\*.vrt ..\bin\reports\ >nul
echo.
"..\bin\DieVixTests.exe"
exit /b %errorlevel%
