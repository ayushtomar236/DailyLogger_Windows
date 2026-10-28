# Design

## Context

The original DailyLogger application on macOS uses SwiftUI (`FloatingPromptView.swift`) with a dark, translucent HUD window (`.hudWindow` material), 540x380 px floating dimensions, 14px rounded corners, an indigo gradient icon, multiline prompt editor, past history tab, and `Cmd + Enter` / `Esc` keyboard shortcuts.

On Windows, the initial port relied on multiple external batch files (`install.cmd`, `run-now.cmd`, `status.cmd`, `uninstall.cmd`) and lacked a native desktop UI. This design establishes a unified C# / WPF desktop application (`DailyLogger.exe`) that matches the macOS UI 1:1 and manages its own Task Scheduler lifecycle directly.

See `proposal.md` for motivation and `specs/` for capability specifications.

## Goals / Non-Goals

**Goals:**
- Provide a single Windows desktop executable (`DailyLogger.exe`) that handles the reflection prompt, history viewer, and self-scheduling.
- Exactly match the macOS HUD visual design: 540x380 size, 14px rounded corners, dark glassmorphism styling, header icon gradient, Prompt/History toggle, and footer actions.
- Embed Task Scheduler registration and uninstallation directly into the executable (accessible via `--setup`, `--uninstall`, or the in-app Schedule settings dialog), eliminating external `.cmd` files.
- Deliver zero-subprocess latency for UI operations by reading and appending to `%LOCALAPPDATA%\DailyLogger\daily_logs.txt` natively.

**Non-Goals:**
- Retaining multiple standalone `.cmd` files for routine tasks.
- Cloud sync, accounts, or database servers.

## Decisions

### 1. WPF Window Architecture & Visual Matching
* **Decision**: Implement the window using WPF (`MainWindow.xaml`) with borderless custom chrome:
  - `WindowStyle="None"`, `AllowsTransparency="True"`, `Background="Transparent"`
  - Outer `Border` with `CornerRadius="14"`, background `#1C1C1E` (Apple dark HUD style), `BorderBrush="#38383A"`, `BorderThickness="1"`, and soft drop shadow.
  - **Header**:
    - 44x44 rounded square (radius 10) with Indigo-to-Purple linear gradient (`#4F46E5` to `#7C3AED`) and white pencil icon.
    - Title: "Daily Reflection" (bold, rounded font, 18pt).
    - Subtitle: "What did you do today? • YYYY-MM-DD" (12pt, secondary text `#8E8E93`).
    - Top-right toggle button: "History" / "Prompt" with icon.
    - Gear icon button to open the in-app Schedule Settings.
  - **Content Area**:
    - *Prompt Mode*: Multiline TextBox with `#2C2C2E` background, 10px rounded corners, 14pt typography, and watermark placeholder text.
    - *History Mode*: Smooth scrollable list displaying past reflection cards with bold date tags in `#6366F1`, timestamps, and full text.
  - **Footer**:
    - Left: "Dismiss" (`Esc`) button.
    - Right: "Save Log" prominent button (`Ctrl + Enter`) styled in `#4F46E5` indigo with checkmark and spinner indicator.
* **Rationale**: Recreates the exact visual experience of `FloatingPromptView.swift` on Windows.

### 2. In-App Task Scheduler Engine (`TaskSchedulerService`)
* **Decision**: Implement a native C# `TaskSchedulerService` using Windows Task Scheduler COM APIs / `schtasks`:
  - Methods: `RegisterDailyTask(int hour, int minute)`, `UnregisterTask()`, `GetTaskStatus()`.
  - Supports command-line switches:
    - `DailyLogger.exe --setup`: Registers the daily task and creates Start Menu shortcut.
    - `DailyLogger.exe --uninstall`: Removes the task and shortcuts.
    - `DailyLogger.exe --status`: Prints diagnostics to console or opens status dialog.
  - Supports GUI settings: Users can click the gear icon in the header to change prompt time and click "Save & Schedule" directly from the app.
* **Rationale**: Users no longer need to execute separate batch files; one executable handles both the UI and background registration.

### 3. Native Storage Engine (`LogService`)
* **Decision**: Implement C# service that reads and writes UTF-8 JSON Lines to `%LOCALAPPDATA%\DailyLogger\daily_logs.txt`:
  - Implements the night-owl cutoff: entries between `00:00` and `04:59` belong to `Date - 1 day`.
  - Provides thread-safe append with file locking.
  - Provides `GetRecentLogs(int count)` for the in-app history viewer.
* **Rationale**: Eliminates the 200–400ms startup overhead of spawning Python subprocesses from the UI.

### 4. Single-Instance Protection & Focus Management
* **Decision**: Use a named system mutex `Global\DailyLogger_SingleInstance_Mutex`.
  - On launch, if the mutex is already owned, the app uses Win32 `FindWindow` and `SetForegroundWindow` to bring the existing prompt to the foreground and exits.
* **Rationale**: Prevents scheduled tasks and manual launches from creating multiple overlapping windows.

## Risks / Trade-offs

- **[Risk]** Window dragging: Borderless windows do not have a default title bar.
  - **Mitigation**: Add a `MouseDown` handler to the header area (`if (e.ChangedButton == MouseButton.Left) DragMove();`) so users can freely reposition the prompt window on their screen.
- **[Risk]** Windows Task Scheduler permissions when running without elevation.
  - **Mitigation**: Register with `LogonType.InteractiveToken` in the current user's session (`UserId = %USERNAME%`). Standard user accounts have full permission to manage their own scheduled tasks.

## Application Architecture

```text
DailyLogger.exe
├── Presentation (WPF)
│   ├── MainWindow.xaml (540x380 HUD Window, 14px radius)
│   ├── ViewModels/PromptViewModel.cs (Prompt & History state)
│   └── Dialogs/ScheduleSettingsDialog.xaml (In-app schedule editor)
├── Services
│   ├── LogService.cs (JSONL read/append, night-owl date logic)
│   ├── TaskSchedulerService.cs (Register/Unregister Windows Task)
│   └── SingleInstanceService.cs (Mutex & window activation)
└── Storage
    └── %LOCALAPPDATA%\DailyLogger\
        ├── daily_logs.txt (UTF-8 JSONL)
        └── config.json (Schedule settings)
```
