# Spec Delta

## Purpose

Provides a zero-configuration, one-click installation and lifecycle management experience on Windows, configuring background scheduling and application shortcuts with fully self-contained dependencies.

## ADDED Requirements

### Requirement: One-Click Execution via Batch Runner
The installation system SHALL provide a double-clickable batch script (`install.cmd`) that invokes the setup engine via PowerShell with execution policy bypass (`-ExecutionPolicy Bypass -NoProfile`) without requiring manual terminal commands or administrator privileges.

#### Scenario: User double-clicks install.cmd
- **WHEN** user executes `install.cmd` from Windows Explorer
- **THEN** setup executes PowerShell installation without execution policy blocking errors and proceeds with user-level installation

#### Scenario: Installation failure reporting
- **WHEN** any prerequisite or installation step fails
- **THEN** the runner displays an error message to stderr/console and pauses with an exit prompt before closing

### Requirement: Self-Contained Dependency Layout
The installer distribution SHALL bundle all necessary runtime dependencies, including an isolated embedded Python runtime and self-contained .NET application binaries, requiring zero pre-installed developer tools or runtime frameworks on the target Windows system.

#### Scenario: Running on clean Windows system
- **WHEN** installed on a Windows machine without Python or .NET SDK/Runtime installed in PATH
- **THEN** the application and its backend processes execute successfully using bundled local runtimes

### Requirement: User-Level Application Installation
The installer SHALL copy application files, configuration, and bundled runtime components into per-user directories under `%LOCALAPPDATA%\Programs\DailyLogger`, and initialize `%LOCALAPPDATA%\DailyLogger` for logs and user data without requiring administrative elevation.

#### Scenario: First-time install directory creation
- **WHEN** installation executes on a system where DailyLogger directories do not exist
- **THEN** setup creates `%LOCALAPPDATA%\Programs\DailyLogger` and `%LOCALAPPDATA%\DailyLogger\logs` with current user read/write permissions

### Requirement: Windows Task Scheduler Registration
The installer SHALL register scheduled tasks in the interactive user's Windows Task Scheduler session, including a daily prompt trigger at the configured time (with missed-run catch-up policy enabled) and a user logon trigger.

#### Scenario: Scheduled daily trigger registration
- **WHEN** setup completes
- **THEN** a Task Scheduler job named `DailyLogger` is active with a daily trigger, logon trigger, and "Run task as soon as possible after a scheduled start is missed" enabled

### Requirement: Start Menu and Shortcut Integration
The installer SHALL create a Start Menu shortcut named "DailyLogger" pointing to the launcher executable so the user can open or test the daily reflection prompt on demand.

#### Scenario: Start Menu shortcut creation
- **WHEN** installation finishes
- **THEN** a shortcut is present in the current user's Start Menu programs directory pointing to the installed application launcher

### Requirement: Safe Clean Uninstallation
The system SHALL provide a double-clickable uninstaller (`uninstall.cmd`) that deregisters scheduled tasks and deletes installed binaries, while preserving the user's `daily_logs.txt` data file by default.

#### Scenario: Default uninstallation
- **WHEN** user executes `uninstall.cmd`
- **THEN** the Task Scheduler task is removed, Start Menu shortcut is deleted, application files under `%LOCALAPPDATA%\Programs\DailyLogger` are removed, and `%LOCALAPPDATA%\DailyLogger\daily_logs.txt` is retained

#### Scenario: Uninstallation when task does not exist
- **WHEN** uninstallation runs on a system where the scheduled task was already removed
- **THEN** uninstallation succeeds gracefully without error

### Requirement: Smoke Test Verification Runner
The installer SHALL provide a verification runner (`run-now.cmd`) and diagnostic script (`status.cmd`) that tests whether the application can launch and verify current logging status immediately after installation.

#### Scenario: User runs run-now.cmd
- **WHEN** user executes `run-now.cmd` after installation
- **THEN** the launcher executes, checks daily logging status, and displays the reflection prompt if not yet logged today
