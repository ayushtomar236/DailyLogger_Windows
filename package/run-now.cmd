@echo off
setlocal

title DailyLogger Prompt

set "APP_EXE=%LOCALAPPDATA%\Programs\DailyLogger\bin\DailyLogger.App.exe"
if exist "%APP_EXE%" (
    start "" "%APP_EXE%"
    exit /b 0
)

set "APP_CMD=%LOCALAPPDATA%\Programs\DailyLogger\bin\DailyLogger.App.cmd"
if exist "%APP_CMD%" (
    call "%APP_CMD%"
    exit /b 0
)

rem Check current folder or package folder
if exist "%~dp0package\bin\DailyLogger.App.exe" (
    start "" "%~dp0package\bin\DailyLogger.App.exe"
    exit /b 0
)

rem Direct backend invocation fallback for testing
set "PYTHON_EXE=%LOCALAPPDATA%\Programs\DailyLogger\runtime\python\python.exe"
if not exist "%PYTHON_EXE%" set "PYTHON_EXE=%~dp0package\runtime\python\python.exe"
if not exist "%PYTHON_EXE%" set "PYTHON_EXE=python"

set "BACKEND_PY=%LOCALAPPDATA%\Programs\DailyLogger\backend\logger.py"
if not exist "%BACKEND_PY%" set "BACKEND_PY=%~dp0backend\logger.py"

if exist "%BACKEND_PY%" (
    echo Launching DailyLogger backend check...
    "%PYTHON_EXE%" "%BACKEND_PY%" has-logged
    echo.
    echo To record a test reflection directly, enter your reflection below:
    set /p "USER_ENTRY=> "
    if not "!USER_ENTRY!"=="" (
        "%PYTHON_EXE%" "%BACKEND_PY%" log --text "!USER_ENTRY!"
    )
    pause
    exit /b 0
)

echo [ERROR] DailyLogger executable not found.
echo Please run install.cmd first to install DailyLogger.
pause
exit /b 1
