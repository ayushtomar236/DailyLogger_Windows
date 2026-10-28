# Proposal

## Why

Setting up DailyLogger on Windows currently requires manual command-line interaction, PowerShell execution policy adjustments, environment configuration, and manual Windows Task Scheduler registration. To make DailyLogger accessible to non-technical users and ensure friction-free setup on any Windows machine, a one-click installation mechanism is needed. By providing a double-clickable installer runner with self-contained dependencies (embedded Python and self-contained .NET binary), users can install, schedule, and run DailyLogger without pre-installing developer runtimes or opening a terminal.

## What Changes

- Add a double-clickable `install.cmd` (batch runner) that launches the underlying installation PowerShell script with execution policy bypass (`-ExecutionPolicy Bypass -NoProfile`), allowing zero-configuration installation.
- Implement a self-contained distribution packaging structure that bundles an embedded Python runtime alongside the self-contained WPF application, eliminating requirements for external Python or .NET runtime installations.
- Automate configuration of per-user application directories under `%LOCALAPPDATA%\Programs\DailyLogger` (binaries) and `%LOCALAPPDATA%\DailyLogger` (user data and logs).
- Automate registration of Windows Task Scheduler tasks (daily prompt trigger at configured hour and logon/catch-up trigger) in the interactive user session.
- Create Start Menu shortcut ("DailyLogger") pointing to the launcher for manual on-demand triggers.
- Add double-clickable `uninstall.cmd` and `uninstall.ps1` to cleanly deregister scheduled tasks and remove application binaries while preserving the user's `daily_logs.txt` data file by default.
- Provide `run-now.cmd` and `status.cmd` utility runners for immediate testing and diagnostics.

## Capabilities

### New Capabilities
- `windows-installer`: Manages the automated, self-contained one-click installation, Task Scheduler registration, Start Menu integration, and clean uninstallation on Windows.

### Modified Capabilities
*(None - this is the initial specification for Windows installation)*

## Impact

- **New Files**:
  - `scripts/install.cmd`, `scripts/install.ps1`
  - `scripts/uninstall.cmd`, `scripts/uninstall.ps1`
  - `scripts/run-now.cmd`, `scripts/status.ps1`, `scripts/status.cmd`
  - Packaging configuration/scripts for staging the self-contained .NET app and embedded Python distribution.
- **Dependencies**: Uses Windows built-in PowerShell and Task Scheduler; bundles embedded Python (3.11+ embeddable zip) and self-contained .NET single-file runtime.
- **User Experience**: The user downloads/extracts the release zip and double-clicks `install.cmd`; the app is fully configured and scheduled within seconds without elevated/admin privileges.
