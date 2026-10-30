@echo off
setlocal
cd /d "%~dp0\.."

set TARGET=src\Database\DieVix_Schema_Firebird5.sql
echo Regenerating %TARGET% from migrations...

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0regenerate_schema.ps1"

if errorlevel 1 (
    echo [ERROR] Schema regeneration failed!
    exit /b 1
)
exit /b 0
