# DailyLogger (Windows)

A distraction-free daily reflection prompt for Windows with zero-configuration setup, local-first storage, and automatic scheduling.

---

## Features

- **Distraction-Free Prompt**: Displays a floating prompt at your scheduled daily reflection time.
- **Night-Owl Date Attribution**: Entries created between `00:00` and `04:59` belong to the previous logical day.
- **One-Click Installation**: Zero-dependency installation via a double-clickable batch runner. No administrator privileges or developer runtimes required.
- **Automatic Scheduling**: Windows Task Scheduler integration with daily trigger and missed-run catch-up (prompts upon logon/wake if your computer was asleep at the scheduled time).
- **Local-First & Private**: Reflection entries are stored locally as human-readable JSON Lines (JSONL) in `%LOCALAPPDATA%\DailyLogger\daily_logs.txt`. No cloud, no analytics, no open network ports.
- **Preserved History**: Uninstallation cleanly removes scheduled tasks and application files while preserving your reflection history by default.

---

## Quick Start: One-Click Installation

1. Download and extract the `DailyLogger-Windows-x64.zip` release package.
2. Double-click **`install.cmd`**.

That's it! The installer will:
- Copy the application and bundled runtimes to `%LOCALAPPDATA%\Programs\DailyLogger`.
- Initialize your data and log directories at `%LOCALAPPDATA%\DailyLogger`.
- Register the `DailyLogger` scheduled task (defaults to 02:00 daily, plus logon catch-up).
- Add a "DailyLogger" shortcut to your Start Menu.

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
