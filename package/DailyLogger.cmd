@echo off
setlocal

set "APP_DIR=%~dp0.."
set "PYTHON_EXE=%APP_DIR%\runtime\python\python.exe"
if not exist "%PYTHON_EXE%" set "PYTHON_EXE=python"

set "BACKEND_PY=%APP_DIR%\backend\logger.py"

"%PYTHON_EXE%" "%BACKEND_PY%" %*
