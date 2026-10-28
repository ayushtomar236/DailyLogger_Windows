@echo off
setlocal enabledelayedexpansion

title DailyLogger Uninstaller

echo ========================================================
echo   DailyLogger - One-Click Windows Uninstaller
echo ========================================================
echo.
echo This will remove the scheduled task, shortcuts, and application binaries.
echo Your saved reflection logs will NOT be deleted.
echo.
set /p "CONFIRM=Are you sure you want to uninstall DailyLogger? (Y/N): "
if /i not "!CONFIRM!"=="Y" (
    echo Uninstallation cancelled.
    pause
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%scripts\uninstall.ps1"

if not exist "%PS_SCRIPT%" (
    set "PS_SCRIPT=%LOCALAPPDATA%\Programs\DailyLogger\scripts\uninstall.ps1"
)

if not exist "%PS_SCRIPT%" (
    set "PS_SCRIPT=%SCRIPT_DIR%package\scripts\uninstall.ps1"
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

echo.
pause
