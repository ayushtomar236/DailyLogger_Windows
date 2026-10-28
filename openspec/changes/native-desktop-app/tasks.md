# Tasks

## 1. WPF Project Setup & Core Services

- [x] 1.1 Create the .NET WPF project structure under `windows/src/DailyLogger.App` and solution file `windows/DailyLogger.sln`, and verify project files exist.
- [x] 1.2 Implement `LogService.cs` handling UTF-8 JSON Lines read/append, logical date cutoff (00:00-04:59 attributed to D-1), and history queries, and verify JSONL parsing and append behavior.
- [x] 1.3 Implement `TaskSchedulerService.cs` supporting direct registration, schedule update, and deregistration using Windows Task Scheduler APIs, and verify scheduling logic.
- [x] 1.4 Implement `SingleInstanceService.cs` using a named system mutex and window activation Win32 calls, and verify mutex lock behavior.

## 2. Mac-Identical HUD User Interface

- [x] 2.1 Implement `MainWindow.xaml` with borderless custom chrome (540x380 px, 14px rounded corners, dark HUD visual effect brush, and window drag support), verifying visual layout matches specs.
- [x] 2.2 Implement the header section with 44x44 indigo gradient pencil icon, "Daily Reflection" title, target date subtitle, and "History" toggle button, verifying mode toggle switching.
- [x] 2.3 Implement the prompt editor view with multiline TextBox, placeholder watermark, and `Ctrl + Enter` save handler, verifying save submission and text validation.
- [x] 2.4 Implement the history viewer rendering recent reflection cards with bold date tags, timestamps, and scrollable container, verifying past entries load properly.
- [x] 2.5 Implement the in-app Schedule Settings dialog/flyout accessible via a header gear button to adjust prompt time, and verify schedule persistence to `config.json`.

## 3. CLI Arguments & Packaging Integration

- [x] 3.1 Implement command-line switches in `App.xaml.cs` (`--setup`, `--uninstall`, `--status`) allowing headless direct task scheduling from the executable, and verify argument parsing.
- [x] 3.2 Update `scripts/build-package.ps1` to publish `DailyLogger.exe` as a self-contained single-file binary, deprecating redundant `.cmd` runners, and verify single-file build output.
- [x] 3.3 Update `README.md` and `SETUP.md` with instructions for running and self-scheduling the unified executable directly, and verify documentation matches executable capabilities.
