# DailyLogger — Windows Setup Guide

Welcome to **DailyLogger**! This guide walks you through installing, customizing, and managing DailyLogger on your Windows computer.

---

## ⚡ Quick Start: Zero-Friction Setup

You do **not** need administrator rights, Python, or developer tools installed on your PC.

### Method A: Graphical Setup (One-Click)
1. Download and extract `DailyLogger-Windows-x64.zip`.
2. Double-click **`DailyLogger.exe`** (or `install.cmd`).
3. The sleek Mac-identical reflection prompt opens.
4. Click the **⚙ Settings** button in the header, choose your preferred daily reflection time, and click **Save & Schedule**.

### Method B: Command-Line One-Step Schedule
From Command Prompt or PowerShell:
```cmd
DailyLogger.exe --setup 21 30
```
*(This directly schedules the task for 9:30 PM and creates the Start Menu shortcut — no `.cmd` scripts needed!)*

---

## 🎨 Visual Experience: Identical to Mac

DailyLogger on Windows matches the original macOS version 1:1:
- **540 × 380 Floating HUD**: Dark glassmorphism card with 14px rounded corners and soft drop shadow.
- **Header**: Indigo-to-purple gradient pencil icon, "Daily Reflection" title, and logical date subtitle.
- **Prompt Mode**: Clean multiline editor with watermark guidance.
- **History Mode**: Click the **"History"** button in the header to browse past reflection cards with timestamps.
- **Keyboard Navigation**: Press **`Ctrl + Enter`** to save, or **`Esc`** to dismiss.

---

## 🚀 How to Use DailyLogger

### 1. Automatic Daily Prompt
At your scheduled reflection time:
- The floating HUD prompt appears on your desktop asking *"What did you do today?"*.
- Type your reflection.
- Press **`Ctrl + Enter`** to save.

### 2. Missed Schedule / Sleep Catch-Up
If your computer was asleep or turned off at your scheduled time:
- Windows Task Scheduler automatically triggers the prompt as soon as you wake or log in to your PC.

### 3. Open on Demand
You can open DailyLogger anytime:
- Press the **Windows Key**, type `DailyLogger`, and hit **Enter**.
- Or run **`DailyLogger.exe`** directly.

---

## ⚙️ Customizing Your Scheduled Time

You can customize your scheduled prompt time in two ways:
1. **In-App GUI**: Click the **⚙** gear icon in the header, adjust the hour and minute, and click **Save & Schedule**.
2. **From Terminal**: Run `DailyLogger.exe --setup <hour> <minute>` (e.g. `DailyLogger.exe --setup 22 00`).
3. **Manual Config**: Or edit `%LOCALAPPDATA%\DailyLogger\config.json`:
   ```text
   %LOCALAPPDATA%\DailyLogger\config.json
   ```
2. Open it with Notepad and update the `hour` (0–23) and `minute` (0–59):
   ```json
   {
     "hour": 22,
     "minute": 30
   }
   ```
   *(The above example sets the prompt for 10:30 PM)*.
3. Save the file and double-click **`install.cmd`** again. The scheduled task will instantly update with your new time.

---

## 🛠️ Utility Runners

The extracted folder and the installed app folder include 4 convenient batch runners:

| File | Purpose |
|---|---|
| **`install.cmd`** | Installs or updates DailyLogger and refreshes your schedule. |
| **`run-now.cmd`** | Tests the prompt immediately or records a quick reflection. |
| **`status.cmd`** | Shows installation health, Task Scheduler state, next run time, and today's log status. |
| **`uninstall.cmd`** | Completely removes the app and tasks while keeping your reflections safe. |

---

## 📂 Where Your Data is Stored

All your reflection data remains strictly on your local computer:

* **Daily Reflection Logs**: `%LOCALAPPDATA%\DailyLogger\daily_logs.txt`
* **Schedule Configuration**: `%LOCALAPPDATA%\DailyLogger\config.json`
* **Technical Diagnostics**: `%LOCALAPPDATA%\DailyLogger\logs\`

### Backing Up Your Reflections
Your reflections are stored as plain UTF-8 text (JSON Lines format). To back up your data, simply copy `daily_logs.txt` to your cloud drive, external USB, or backup folder.

---

## 🗑️ How to Uninstall

If you ever wish to remove DailyLogger:

1. Double-click **`uninstall.cmd`**.
2. Type `Y` to confirm.

The uninstaller will:
- Stop any running DailyLogger processes.
- Remove the scheduled task from Windows Task Scheduler.
- Remove the Start Menu shortcut.
- Delete the application binaries.
- **Keep your saved reflection history** (`daily_logs.txt`) completely safe and untouched.

---

## ❓ Frequently Asked Questions

**Q: Does DailyLogger require an internet connection?**  
No. DailyLogger is 100% local-first and never sends data over the internet.

**Q: What is the "night-owl" rule?**  
Entries logged between `00:00` and `04:59` AM are attributed to the previous calendar day. If you stay up past midnight journaling your evening, your entry belongs to the day that just concluded.

**Q: Can I run multiple reflections in one day?**  
Yes. Each time you save, a new timestamped record is appended to your log file.
