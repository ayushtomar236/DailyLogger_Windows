# Proposal

## Why

Currently, DailyLogger on Windows relies on multiple external `.cmd` and `.ps1` batch runners (`install.cmd`, `run-now.cmd`, `status.cmd`, `uninstall.cmd`), which clutters the directory, requires terminal windows for routine actions, and separates the prompt UI from setup operations. Furthermore, users expect the Windows port to match the premium, distraction-free visual aesthetic of the original macOS application (`FloatingPromptView.swift`), including HUD glassmorphism, rounded corners, indigo accent styling, keyboard-first navigation (`Ctrl + Enter`, `Esc`), and a built-in History viewer.

By building a unified Windows native desktop executable (`DailyLogger.exe`) with integrated Task Scheduler management and a 1:1 visual fidelity match to the macOS Swift UI, users get a seamless, single-binary experience that configures its own schedule and provides an identical reflection prompt.

## What Changes

- **Direct In-App Task Scheduler Management**: Build scheduling and lifecycle commands directly into the executable (`DailyLogger.exe --setup`, `DailyLogger.exe --uninstall`, `DailyLogger.exe --status`, and an in-app Schedule Settings dialog), replacing reliance on multiple `.cmd` files.
- **Mac-Identical Visual UI**:
  - 540x380 floating window with 14px corner radius and dark/light translucent glassmorphism (Acrylic / Mica HUD styling).
  - Gradient icon header with pencil outline, title "Daily Reflection", and dynamic subtitle ("What did you do today? • [Date]").
  - Mode toggle button between **"Prompt"** and **"History"** with smooth transitions.
  - Multiline editor with subtle border, line spacing, and contextual placeholder text.
  - History viewer rendering past reflection cards with bold date tags, timestamps, and scrollable entries.
  - Standardized keyboard navigation: `Ctrl + Enter` to save (with spinner feedback), `Esc` to dismiss.
- **Unified Single-Binary Distribution**: The application handles execution, daily scheduled launches, manual prompts, and setup management without spawning command prompt windows.

## Capabilities

### New Capabilities
- `desktop-prompt-ui`: Floating desktop prompt window providing 1:1 visual fidelity with the macOS DailyLogger UI (glassmorphism HUD, gradient icon header, editor/history toggle, `Ctrl + Enter` submission, `Esc` dismissal).
- `embedded-task-scheduler`: Built-in task scheduling engine within the desktop executable to register, update, and remove the Windows Task Scheduler task and shortcuts directly without external batch scripts.

### Modified Capabilities
*(None - initial implementation of native desktop UI and embedded scheduler)*

## Impact

- **Affected Systems**: Windows desktop app (`windows/src/DailyLogger.App` / `DailyLogger.exe`), replacing the multiple batch script runners with a unified native executable.
- **User Experience**: Users download a single `DailyLogger.exe`, double-click to run/schedule, and enjoy the exact same look and feel as the macOS application.
