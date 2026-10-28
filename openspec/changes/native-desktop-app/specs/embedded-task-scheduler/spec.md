# Spec Delta

## Purpose

Enables the desktop executable to manage Windows Task Scheduler lifecycle events, schedule configuration, and single-instance guards directly without external batch files or PowerShell scripts.

## ADDED Requirements

### Requirement: Direct Task Scheduler Registration
The application executable SHALL provide direct task scheduling capability that registers a Windows Task Scheduler task named "DailyLogger" configured with a daily trigger at the user's scheduled hour and minute, a logon trigger, and missed-run catch-up policy enabled.

#### Scenario: Direct setup execution
- **WHEN** the executable is invoked with `--setup` or the user clicks "Enable Schedule" in settings
- **THEN** the application registers the scheduled task directly with Windows Task Scheduler without spawning external batch or PowerShell scripts

### Requirement: Direct Task Scheduler Deregistration
The application executable SHALL support removing the scheduled task and Start Menu shortcuts via `--uninstall` command or in-app action, while preserving `%LOCALAPPDATA%\DailyLogger\daily_logs.txt`.

#### Scenario: Direct uninstall execution
- **WHEN** the executable is invoked with `--uninstall`
- **THEN** the scheduled task is deleted, application shortcuts are removed, and user log records are preserved

### Requirement: In-App Schedule Customization
The application SHALL allow users to view and update the scheduled trigger time directly, persisting changes to `%LOCALAPPDATA%\DailyLogger\config.json` and updating the active Task Scheduler task trigger.

#### Scenario: Updating scheduled hour
- **WHEN** user updates the prompt hour in the application and applies changes
- **THEN** the new time is saved to `config.json` and the Windows Task Scheduler trigger time is updated immediately

### Requirement: Single-Instance Enforcement
The application SHALL enforce single-instance execution using a system named mutex, bringing the existing active window to the foreground if a second launch is triggered manually or by scheduler.

#### Scenario: Overlapping task trigger while window is open
- **WHEN** a scheduled task fires while the user already has the reflection prompt open
- **THEN** the second instance exits immediately and the existing prompt window is focused without duplicating windows
