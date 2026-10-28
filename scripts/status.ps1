<#
.SYNOPSIS
    Reports installation, scheduling, and logging status for DailyLogger.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "SilentlyContinue"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " DailyLogger Status & Diagnostics         " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\DailyLogger"
$DataDir = Join-Path $env:LOCALAPPDATA "DailyLogger"
$LogFile = Join-Path $DataDir "daily_logs.txt"
$taskName = "DailyLogger"

# 1. Installation Status
Write-Host "`n--- [Installation] ---" -ForegroundColor Yellow
if (Test-Path $InstallDir) {
    Write-Host "Installed: YES" -ForegroundColor Green
    Write-Host "Location:  $InstallDir"
    
    $launcher = Join-Path $InstallDir "bin\DailyLogger.App.exe"
    if (-not (Test-Path $launcher)) {
        $launcher = Join-Path $InstallDir "bin\DailyLogger.App.cmd"
    }
    Write-Host "Launcher:  $launcher (Exists: $(Test-Path $launcher))"
    
    $pythonExe = Join-Path $InstallDir "runtime\python\python.exe"
    Write-Host "Runtime:   $pythonExe (Exists: $(Test-Path $pythonExe))"
} else {
    Write-Host "Installed: NO (Not found at $InstallDir)" -ForegroundColor Red
}

# 2. Scheduled Task Status
Write-Host "`n--- [Task Scheduler] ---" -ForegroundColor Yellow
try {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
    Write-Host "Task Name:   $($task.TaskName)" -ForegroundColor Green
    Write-Host "Task State:  $($task.State)"
    
    $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName
    Write-Host "Last Run:    $($taskInfo.LastRunTime)"
    Write-Host "Last Result: $($taskInfo.LastTaskResult)"
    Write-Host "Next Run:    $($taskInfo.NextRunTime)"
} catch {
    Write-Host "Scheduled Task '$taskName' NOT found." -ForegroundColor Red
}

# 3. User Reflection Logs
Write-Host "`n--- [Daily Reflection Logs] ---" -ForegroundColor Yellow
if (Test-Path $LogFile) {
    Write-Host "Log File: $LogFile" -ForegroundColor Green
    $lines = Get-Content $LogFile | Where-Object { $_.Trim() -ne "" }
    Write-Host "Total Records: $($lines.Count)"
    
    # Check today's status via backend
    $backendScript = Join-Path $InstallDir "backend\logger.py"
    $pythonExe = Join-Path $InstallDir "runtime\python\python.exe"
    if (-not (Test-Path $pythonExe)) { $pythonExe = "python" }
    
    if (Test-Path $backendScript) {
        $result = & $pythonExe $backendScript --file $LogFile has-logged 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Logged Today:  YES" -ForegroundColor Green
        } else {
            Write-Host "Logged Today:  NO (Reflection pending)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "No log file found yet at $LogFile." -ForegroundColor Yellow
}

# 4. Start Menu Shortcut
Write-Host "`n--- [Shortcuts] ---" -ForegroundColor Yellow
$shortcut = Join-Path ([System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs")) "DailyLogger.lnk"
Write-Host "Start Menu Shortcut: $(if (Test-Path $shortcut) { 'Present' } else { 'Missing' })"

Write-Host "`n==========================================" -ForegroundColor Cyan
