@echo off
setlocal enabledelayedexpansion

title DailyLogger Installer

echo ========================================================
echo   DailyLogger - One-Click Windows Installer
echo ========================================================
echo.

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%scripts\install.ps1"

if not exist "%PS_SCRIPT%" (
    set "PS_SCRIPT=%SCRIPT_DIR%package\scripts\install.ps1"
)

if not exist "%PS_SCRIPT%" (
    echo [ERROR] Installation script not found at %PS_SCRIPT%
    echo Please make sure the release package is properly extracted.
    echo.
    pause
    exit /b 1
)

echo Launching PowerShell installer with ExecutionPolicy Bypass...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if %EXIT_CODE% equ 0 (
    echo [SUCCESS] DailyLogger installation completed successfully!
) else (
    echo [FAILED] Installation encountered an error (exit code: %EXIT_CODE%).
)

echo.
pause
exit /b %EXIT_CODE%
