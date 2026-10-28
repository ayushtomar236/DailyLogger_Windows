<#
.SYNOPSIS
    Uninstalls DailyLogger and removes scheduled tasks while preserving user reflection logs.

.DESCRIPTION
    - Stops any running DailyLogger processes
    - Deregisters the Windows Task Scheduler task
    - Removes Start Menu shortcut
    - Removes installed binaries under %LOCALAPPDATA%\Programs\DailyLogger
    - By default, PRESERVES user log files under %LOCALAPPDATA%\DailyLogger\daily_logs.txt
    - Optional -PurgeData switch to delete all user data if explicitly requested
#>

[CmdletBinding()]
param(
    [switch]$PurgeData,
    [switch]$Quiet
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " DailyLogger Windows Uninstaller         " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\DailyLogger"
$DataDir = Join-Path $env:LOCALAPPDATA "DailyLogger"
$LogFile = Join-Path $DataDir "daily_logs.txt"
$taskName = "DailyLogger"
$shortcutPath = Join-Path ([System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs")) "DailyLogger.lnk"

# 1. Stop any running instances
Write-Host "[1/4] Stopping active DailyLogger processes..." -ForegroundColor Green
Get-Process -Name "DailyLogger*" | Stop-Process -Force -ErrorAction SilentlyContinue

# 2. Unregister Windows Task Scheduler Task
Write-Host "[2/4] Removing scheduled task '$taskName'..." -ForegroundColor Green
try {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
    Write-Host "  Scheduled task '$taskName' removed."
} catch {
    # Fallback to schtasks.exe
    $output = schtasks /Delete /TN "$taskName" /F 2>&1
    Write-Host "  Scheduled task removal completed."
}

# 3. Remove Start Menu Shortcut
Write-Host "[3/4] Removing Start Menu shortcut..." -ForegroundColor Green
if (Test-Path $shortcutPath) {
    Remove-Item -Path $shortcutPath -Force
    Write-Host "  Shortcut removed: $shortcutPath"
} else {
    Write-Host "  No shortcut found."
}

# 4. Remove Application Files
Write-Host "[4/4] Removing installed application files..." -ForegroundColor Green
if (Test-Path $InstallDir) {
    Remove-Item -Path $InstallDir -Recurse -Force
    Write-Host "  Removed binaries from: $InstallDir"
}

# 5. Handle User Data (Preserve by Default)
Write-Host ""
if ($PurgeData) {
    if (Test-Path $DataDir) {
        Remove-Item -Path $DataDir -Recurse -Force
        Write-Host "All user data purged from $DataDir as requested." -ForegroundColor Yellow
    }
} else {
    if (Test-Path $LogFile) {
        Write-Host "===========================================================" -ForegroundColor Green
        Write-Host " User reflections preserved successfully at:               " -ForegroundColor Green
        Write-Host "   $LogFile" -ForegroundColor Cyan
        Write-Host " To completely delete user data, remove this folder manually." -ForegroundColor Gray
        Write-Host "===========================================================" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "DailyLogger has been uninstalled." -ForegroundColor Cyan
