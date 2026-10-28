@echo off
setlocal

title DailyLogger Status

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%scripts\status.ps1"

if not exist "%PS_SCRIPT%" (
    set "PS_SCRIPT=%LOCALAPPDATA%\Programs\DailyLogger\scripts\status.ps1"
)

if not exist "%PS_SCRIPT%" (
    set "PS_SCRIPT=%SCRIPT_DIR%package\scripts\status.ps1"
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

echo.
pause
