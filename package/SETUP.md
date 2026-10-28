# DailyLogger — Windows Setup Guide

Welcome to **DailyLogger**! This guide walks you through installing, customizing, and managing DailyLogger on your Windows computer.

---

## ⚡ Quick Start: 3-Step Installation

You do **not** need administrator rights, Python, or developer tools installed on your PC.

### Step 1: Download & Extract
1. Download `DailyLogger-Windows-x64.zip`.
2. Right-click the downloaded `.zip` file and select **Extract All...**.
3. Choose an extraction folder (for example, your `Downloads` or `Documents` folder) and click **Extract**.

### Step 2: Run the Installer
1. Open the extracted folder.
2. Double-click **`install.cmd`**.

> **Note on Windows Defender / SmartScreen:**
> Because this is a newly downloaded setup script, Windows might display a blue banner saying *"Windows protected your PC"*.
> - Click **More info**.
> - Click **Run anyway**.

### Step 3: Complete & Verify
The installer runs in a terminal window and automatically:
- Copies application files to `%LOCALAPPDATA%\Programs\DailyLogger`.
- Configures reflection storage at `%LOCALAPPDATA%\DailyLogger\daily_logs.txt`.
- Registers a Windows Task Scheduler task (daily prompt at `02:00` AM, plus wake/logon catch-up).
- Adds a **DailyLogger** shortcut to your Start Menu.

When you see `[SUCCESS] DailyLogger installation completed successfully!`, press any key to close the window.

---

## 🚀 How to Use DailyLogger

### 1. Automatic Daily Prompt
At your scheduled reflection time (default `02:00` AM):
- A clean, distraction-free prompt appears on your desktop asking *"What did you do today?"*.
- Type your reflection.
- Press **`Ctrl + Enter`** to save, or **`Esc`** to dismiss without saving.

### 2. Missed Schedule / Sleep Catch-Up
If your computer was asleep or turned off at your scheduled time:
- Windows Task Scheduler automatically triggers the prompt as soon as you wake or log in to your PC.

### 3. Open on Demand
You can open DailyLogger anytime:
- Press the **Windows Key**, type `DailyLogger`, and hit **Enter**.
- Or double-click **`run-now.cmd`** in your installation folder.

---

## ⚙️ Customizing Your Scheduled Time

By default, DailyLogger prompts at **2:00 AM** (`02:00`). To change the time:

1. Press `Win + R`, paste the following path, and press Enter:
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
