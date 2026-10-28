# DailyLogger (Windows)

A distraction-free daily reflection prompt for Windows with zero-configuration setup, local-first storage, and automatic scheduling.

---

## Features

- **1:1 Mac Visual Parity**: Dark HUD glassmorphism window (540x380 px, 14px rounded corners), gradient icon, multiline editor, and built-in History viewer identical to the macOS Swift version.
- **Direct Task Scheduling**: Manage and schedule Windows Task Scheduler tasks directly from the executable (`DailyLogger.exe --setup`) or in-app Settings dialog without relying on multiple separate `.cmd` scripts.
- **Night-Owl Date Attribution**: Entries created between `00:00` and `04:59` belong to the previous logical day.
- **Automatic Scheduling**: Windows Task Scheduler integration with daily trigger and missed-run catch-up (prompts upon logon/wake if your computer was asleep at the scheduled time).
- **Local-First & Private**: Reflection entries are stored locally as human-readable JSON Lines (JSONL) in `%LOCALAPPDATA%\DailyLogger\daily_logs.txt`. No cloud, no analytics, no open network ports.
- **Preserved History**: Uninstallation cleanly removes scheduled tasks and application files while preserving your reflection history by default.

---

## Quick Start: Single-Executable Setup

1. Download and extract `DailyLogger-Windows-x64.zip`.
2. Double-click **`DailyLogger.exe`** (or `install.cmd`).
3. Click the **⚙ Settings** button in the header to pick your preferred prompt time and schedule automatically!

Alternatively, schedule via command line directly:
```cmd
DailyLogger.exe --setup 22 00
```

---

## Utility Runners

The root folder and installed application directory include convenient double-clickable runners:

| Runner | Description |
|---|---|
| **`install.cmd`** | Installs or updates DailyLogger, registers scheduled tasks, and creates shortcuts. |
| **`run-now.cmd`** | Triggers an immediate reflection prompt or CLI entry for testing. |
| **`status.cmd`** | Displays installation health, Task Scheduler state, next run time, and today's log status. |
| **`uninstall.cmd`** | Deregisters tasks and removes binaries while safely keeping your `daily_logs.txt` intact. |

---

## Manually Invoking DailyLogger on Windows

You can trigger or test DailyLogger anytime using any of the following methods:

### 1. Double-Click `run-now.cmd` (Easiest)
In your extracted folder or `%LOCALAPPDATA%\Programs\DailyLogger`:
* Double-click **`run-now.cmd`** to immediately open the prompt or record an entry.

### 2. From the Windows Start Menu
* Press the **Windows Key**, type **`DailyLogger`**, and press **Enter**.

### 3. Trigger the Scheduled Task Directly
To test the exact background trigger registered with Windows Task Scheduler:
* **In PowerShell**:
  ```powershell
  Start-ScheduledTask -TaskName "DailyLogger"
  ```
* **In Command Prompt (`cmd.exe`)**:
  ```cmd
  schtasks /Run /TN "DailyLogger"
  ```
* **Task Scheduler GUI**: Press `Win + R`, type `taskschd.msc`, locate `DailyLogger`, right-click and choose **Run**.

### 4. Direct Terminal Commands
```powershell
# Check if logged today (exit code 0 = logged, 1 = not yet)
python "%LOCALAPPDATA%\Programs\DailyLogger\backend\logger.py" has-logged

# Record an entry
python "%LOCALAPPDATA%\Programs\DailyLogger\backend\logger.py" log --text "Finished my milestone"

# View recent entries
python "%LOCALAPPDATA%\Programs\DailyLogger\backend\logger.py" list --limit 5 --pretty
```

## Where Data is Stored

- **Reflections Log**: `%LOCALAPPDATA%\DailyLogger\daily_logs.txt` (UTF-8 JSON Lines)
- **Schedule Configuration**: `%LOCALAPPDATA%\DailyLogger\config.json`
- **Technical Diagnostics**: `%LOCALAPPDATA%\DailyLogger\logs\`
- **Installed Binaries**: `%LOCALAPPDATA%\Programs\DailyLogger\`

### Record Format (JSONL)

Each reflection is appended as a single JSON object per line:

```json
{"id": "d2eb7c4d", "timestamp": "2026-10-24T00:30:15", "date": "2026-10-23", "entry": "Finished my assignment"}
```

---

## Customizing the Schedule

By default, DailyLogger prompts at `02:00` (2:00 AM). To change your scheduled reflection time:

1. Edit `%LOCALAPPDATA%\DailyLogger\config.json`:
   ```json
   {
     "hour": 21,
     "minute": 30
   }
   ```
2. Run **`install.cmd`** again to update the Windows Task Scheduler task with your new time.

---

## CLI Backend Reference

You can also use the backend directly from any terminal:

```powershell
# Record a new reflection
python backend/logger.py log --text "Shipped the new feature"

# Check if you have already logged today (exit code 0 = logged, 1 = not yet)
python backend/logger.py has-logged

# List recent reflections
python backend/logger.py list --limit 10 --reverse --pretty
```

---

## Building the Release Package

To build the self-contained distribution package:

```powershell
# Run from repository root in PowerShell
powershell -ExecutionPolicy Bypass -File scripts\build-package.ps1 -CreateZip
```

This stages the application binaries, bundled embedded Python runtime, and batch runners into `DailyLogger-Windows-x64.zip`.
