<#
.SYNOPSIS
    Installs DailyLogger for the current Windows user without administrator elevation.

.DESCRIPTION
    - Creates per-user application directory under %LOCALAPPDATA%\Programs\DailyLogger
    - Creates per-user data and logs directory under %LOCALAPPDATA%\DailyLogger
    - Copies application binaries, embedded runtime, and backend scripts
    - Creates default config.json if not present
    - Registers Windows Task Scheduler task (daily trigger + logon trigger + missed-run catch-up)
    - Creates Start Menu shortcut for DailyLogger
#>

[CmdletBinding()]
param(
    [int]$ScheduleHour = 2,
    [int]$ScheduleMinute = 0,
    [string]$SourceDir = ""
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " DailyLogger Windows One-Click Installer" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Resolve source and target directories
if ([string]::IsNullOrWhiteSpace($SourceDir)) {
    # Check if run from root (where package/ exists) or from within package directory
    if (Test-Path "$PSScriptRoot\..\package") {
        $SourceDir = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\package")
    } elseif (Test-Path "$PSScriptRoot\..\bin") {
        $SourceDir = [System.IO.Path]::GetFullPath("$PSScriptRoot\..")
    } else {
        $SourceDir = [System.IO.Path]::GetFullPath("$PSScriptRoot\..")
    }
}

$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\DailyLogger"
$DataDir = Join-Path $env:LOCALAPPDATA "DailyLogger"
$LogsDir = Join-Path $DataDir "logs"
$ConfigFile = Join-Path $DataDir "config.json"

Write-Host "Source:      $SourceDir"
Write-Host "Install Dir: $InstallDir"
Write-Host "Data Dir:    $DataDir"
Write-Host ""

# 2. Create Target Directories
Write-Host "[1/5] Creating application directories..." -ForegroundColor Green
foreach ($dir in @($InstallDir, $DataDir, $LogsDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  Created: $dir"
    } else {
        Write-Host "  Exists:  $dir"
    }
}

# 3. Create Default Config if Missing
if (-not (Test-Path $ConfigFile)) {
    Write-Host "[2/5] Creating default configuration..." -ForegroundColor Green
    $defaultConfig = @{
        hour = $ScheduleHour
        minute = $ScheduleMinute
    } | ConvertTo-Json
    Set-Content -Path $ConfigFile -Value $defaultConfig -Encoding UTF8
    Write-Host "  Config written to: $ConfigFile"
} else {
    Write-Host "[2/5] Preserving existing config at: $ConfigFile" -ForegroundColor Yellow
    try {
        $existingConfig = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        if ($existingConfig.hour -ne $null) { $ScheduleHour = [int]$existingConfig.hour }
        if ($existingConfig.minute -ne $null) { $ScheduleMinute = [int]$existingConfig.minute }
    } catch {
        Write-Warning "Could not parse existing config. Using default schedule: $ScheduleHour:$ScheduleMinute"
    }
}

# 4. Copy Application Files
Write-Host "[3/5] Copying application files..." -ForegroundColor Green
$foldersToCopy = @("bin", "backend", "runtime", "scripts")
foreach ($folder in $foldersToCopy) {
    $src = Join-Path $SourceDir $folder
    $dest = Join-Path $InstallDir $folder
    if (Test-Path $src) {
        if (-not (Test-Path $dest)) {
            New-Item -ItemType Directory -Path $dest -Force | Out-Null
        }
        Copy-Item -Path "$src\*" -Destination $dest -Recurse -Force
        Write-Host "  Copied $folder -> $dest"
    }
}

# Copy root batch runners to install dir as well
foreach ($runner in @("run-now.cmd", "status.cmd", "uninstall.cmd")) {
    $srcRunner = Join-Path $SourceDir $runner
    if (Test-Path $srcRunner) {
        Copy-Item -Path $srcRunner -Destination $InstallDir -Force
    } elseif (Test-Path "$PSScriptRoot\..\$runner") {
        Copy-Item -Path "$PSScriptRoot\..\$runner" -Destination $InstallDir -Force
    }
}

# Determine Launcher Executable Path
$launcherExe = Join-Path $InstallDir "bin\DailyLogger.App.exe"
if (-not (Test-Path $launcherExe)) {
    # Check for .cmd launcher fallback
    $launcherCmd = Join-Path $InstallDir "bin\DailyLogger.App.cmd"
    if (Test-Path $launcherCmd) {
        $launcherExe = $launcherCmd
    } else {
        # Fallback to run-now batch runner
        $launcherExe = Join-Path $InstallDir "run-now.cmd"
    }
}

# 5. Register Windows Task Scheduler Task
Write-Host "[4/5] Registering Windows Task Scheduler task..." -ForegroundColor Green
$taskName = "DailyLogger"

try {
    # Form trigger time string (HH:mm)
    $triggerTime = (Get-Date).Date.AddHours($ScheduleHour).AddMinutes($ScheduleMinute).ToString("HH:mm")

    # Action
    $action = New-ScheduledTaskAction -Execute $launcherExe -WorkingDirectory $InstallDir

    # Triggers: Daily at configured time, and AtLogon
    $dailyTrigger = New-ScheduledTaskTrigger -Daily -At $triggerTime
    $logonTrigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

    # Settings: Start ASAP if missed (critical for sleep/wake catch-up!)
    $settings = New-ScheduledTaskSettingsSet `
        -StartWhenAvailable `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -ExecutionTimeLimit (New-TimeSpan -Hours 2)

    # Principal: Current interactive user session
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

    # Register task
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger @($dailyTrigger, $logonTrigger) `
        -Settings $settings `
        -Principal $principal `
        -Description "DailyLogger daily reflection prompt and catch-up trigger" `
        -Force | Out-Null

    Write-Host "  Scheduled task '$taskName' registered successfully (Daily at $triggerTime + On Logon)."
} catch {
    Write-Warning "PowerShell ScheduledTask cmdlet failed: $_. Attempting schtasks fallback..."
    try {
        $schtasksCmd = "schtasks /Create /TN `"$taskName`" /TR `"`"$launcherExe`"`" /SC DAILY /ST $triggerTime /F"
        Invoke-Expression $schtasksCmd | Out-Null
        Write-Host "  Scheduled task registered via schtasks fallback."
    } catch {
        Write-Warning "Could not register scheduled task: $_"
    }
}

# 6. Create Start Menu Shortcut
Write-Host "[5/5] Creating Start Menu shortcut..." -ForegroundColor Green
try {
    $programsMenu = [System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs")
    $shortcutPath = Join-Path $programsMenu "DailyLogger.lnk"

    $wshShell = New-Object -ComObject WScript.Shell
    $shortcut = $wshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $launcherExe
    $shortcut.WorkingDirectory = $InstallDir
    $shortcut.Description = "DailyLogger - Distraction-free daily reflection prompt"
    $shortcut.Save()

    Write-Host "  Shortcut created: $shortcutPath"
} catch {
    Write-Warning "Failed to create Start Menu shortcut: $_"
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " DailyLogger installed successfully!     " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Daily prompt scheduled for:  $ScheduleHour:$($ScheduleMinute.ToString('00'))"
Write-Host "Application path:            $InstallDir"
Write-Host "Logs & reflections saved to: $DataDir\daily_logs.txt"
Write-Host "Test on demand anytime:      $InstallDir\run-now.cmd"
Write-Host ""
