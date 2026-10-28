# Design

## Context

On Windows, DailyLogger relies on a WPF desktop UI, a Python backend, and Windows Task Scheduler. By default, running raw PowerShell `.ps1` files from Windows Explorer opens Notepad or fails due to Windows' default `Restricted` execution policy. Furthermore, standard Windows consumer machines do not have Python or the .NET Desktop SDK/Runtime pre-installed.

To deliver a true "one-click" experience, the installer must bypass execution policy friction, avoid requiring administrative elevation, and bundle all necessary runtimes in an isolated package.

See `proposal.md` for problem motivation and `specs/windows-installer/spec.md` for requirement contracts.

## Goals / Non-Goals

**Goals:**
- Provide double-clickable `.cmd` batch scripts that transparently launch PowerShell with `-ExecutionPolicy Bypass -NoProfile`.
- Install per-user into `%LOCALAPPDATA%\Programs\DailyLogger` without requiring administrator privileges or UAC prompts.
- Bundle an isolated embedded Python runtime and publish the WPF desktop UI as a self-contained executable.
- Automate registration of Windows Task Scheduler tasks for daily prompts and logon/sleep catch-up.
- Create Start Menu shortcut and provide one-click uninstall that preserves user log records.

**Non-Goals:**
- Machine-wide installation into `C:\Program Files` requiring local Administrator rights.
- MSIX packaging or Windows Store distribution.
- Automated code-signing certificate provisioning (signing can be layered onto the published binaries if a certificate is available).

## Decisions

### 1. Batch Wrapper (`install.cmd`) for Execution Policy Bypass
* **Decision**: Provide `install.cmd` as the primary entry point, executing:
  ```cmd
  @echo off
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install.ps1"
  if %ERRORLEVEL% neq 0 (
      echo Installation failed with exit code %ERRORLEVEL%.
      pause
  )
  ```
* **Rationale**: Double-clicking a `.ps1` file in Windows Explorer opens Notepad by default rather than running PowerShell. The `.cmd` launcher guarantees PowerShell execution and bypasses execution policy restrictions without altering machine-wide registry settings.
* **Alternatives Considered**:
  - Self-extracting executable (e.g. 7-Zip SFX): Adds build complexity and false positives from antivirus scanners.
  - Compiling an Inno Setup installer: Requires Inno Setup compiler in CI and makes inspecting the setup script harder.

### 2. Per-User Directory Layout
* **Decision**: Separate application binaries from user data:
  - Binaries & bundled runtimes: `%LOCALAPPDATA%\Programs\DailyLogger`
  - User configuration & logs: `%LOCALAPPDATA%\DailyLogger`
    - `daily_logs.txt`: JSONL entries
    - `logs\`: Technical diagnostics
    - `config.json`: Schedule configuration
* **Rationale**: Writing into `%LOCALAPPDATA%` requires no elevation, adheres to modern Windows per-user app conventions (similar to VS Code user installer), and cleanly separates code updates from user data.
* **Alternatives Considered**:
  - Storing user logs in the install directory: Risk of data loss during app re-installation or upgrades.

### 3. Self-Contained Runtime Bundling
* **Decision**:
  - WPF App: Published using `dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true`.
  - Python Backend: Bundled using official Python Windows embeddable package (`python-3.11.x-embed-amd64`) under `runtime/python/`.
* **Rationale**: Guarantees the application runs immediately on fresh Windows 10/11 installations without prompting the user to install Python, configure environment variables, or install .NET runtimes.
* **Alternatives Considered**:
  - Requiring Python in PATH: Leads to installation failures for non-technical users and version mismatch issues.

### 4. Windows Task Scheduler Registration via PowerShell
* **Decision**: Use PowerShell cmdlets `New-ScheduledTaskTrigger`, `New-ScheduledTaskAction`, `New-ScheduledTaskSettingsSet`, and `Register-ScheduledTask` (or fallback to `schtasks.exe` if cmdlets are restricted):
  - Daily Trigger: Set to configured hour (e.g. 02:00 or user choice).
  - Logon Trigger: Runs at user logon.
  - Settings: `StartWhenAvailable = $true` (ensures missed schedules catch up after sleep or power off).
  - Run Level: `Limited` / current user session (ensures UI prompt displays in interactive desktop session).
* **Rationale**: Task Scheduler is built into every Windows installation and handles wake/logon catch-up natively.

### 5. Data Preservation on Uninstall
* **Decision**: `uninstall.cmd` and `uninstall.ps1` explicitly delete:
  - The Task Scheduler task (`DailyLogger`).
  - Start Menu shortcuts.
  - Binaries in `%LOCALAPPDATA%\Programs\DailyLogger`.
  It **preserves** `%LOCALAPPDATA%\DailyLogger\daily_logs.txt` unless an explicit `-PurgeData` flag is passed.
* **Rationale**: Daily reflections represent personal user history; uninstalling or reinstalling must never silently wipe memories.

## Risks / Trade-offs

- **[Risk]** Windows SmartScreen or antivirus heuristic warnings on downloaded zip/batch files.
  - **Mitigation**: Use transparent, plain-text batch/PowerShell scripts; avoid obfuscated commands; document SmartScreen "More info -> Run anyway" step for unsigned releases.
- **[Risk]** Package size overhead due to bundling .NET runtime and embedded Python (~80 MB uncompressed, ~35 MB compressed).
  - **Mitigation**: Accepted tradeoff to achieve 100% dependency-free installation.
- **[Risk]** User paths containing spaces or special characters (e.g., `C:\Users\John Doe\AppData\...`).
  - **Mitigation**: Enforce strict quotes on all path variables in `.cmd` and `.ps1` scripts.

## Migration & Staging Structure

The distributable release package will be structured as:
```text
DailyLogger-Windows-x64/
├── install.cmd              <-- Double-click to install
├── uninstall.cmd            <-- Double-click to uninstall
├── run-now.cmd              <-- Double-click to test prompt
├── status.cmd               <-- Double-click to view status/diagnostics
└── package/
    ├── bin/
    │   └── DailyLogger.App.exe (self-contained WPF)
    ├── backend/
    │   └── logger.py
    ├── runtime/
    │   └── python/          (isolated embedded Python interpreter)
    └── scripts/
        ├── install.ps1
        ├── uninstall.ps1
        └── status.ps1
```
