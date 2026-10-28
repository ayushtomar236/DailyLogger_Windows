# DailyLogger — Windows Architecture

## 1. Purpose

Port the existing DailyLogger macOS application to Windows while preserving its core behavior:

- A distraction-free daily reflection prompt.
- A floating desktop window that can be dismissed without saving.
- Fast keyboard-first entry and submission.
- Daily scheduling, including a catch-up prompt if the computer was asleep at the scheduled time.
- Local-first storage in a human-readable JSON Lines (JSONL) file.
- Night-owl date attribution: entries created from 00:00 through 04:59 belong to the previous logical day.
- CLI commands to add, list, and check entries.

This document describes the proposed Windows implementation. It is based on the current repository structure and code; it is an implementation plan, not a claim that the Windows port already exists.

Repository: https://github.com/ayushtomar236/DailyLogger

## 2. Current repository assessment

The current codebase contains these important pieces:

- `backend/logger.py`: Python CLI backend. It supports `log`, `has-logged`, and `list`; writes JSON Lines records; generates an ID and timestamp; and computes the logical date.
- `backend/test_logger.py`: Unit tests for logical-date calculation, file append behavior, `has-logged`, and listing.
- `ui/Package.swift` and Swift source under `ui/Sources/DailyLogger`: macOS Swift executable UI package.
- `launchd/com.user.dailylogger.plist`: macOS-specific scheduled-launch configuration.
- `setup.sh`: Bash installer that checks Swift/Python, builds the Swift UI, installs a LaunchAgent, and configures the schedule.
- `README.md`: Existing usage, schedule, and CLI documentation.

### What should be reused

Keep the Python backend and its JSONL record format as the initial source of truth. Preserve the CLI contract where practical so existing scripts and tests continue to work.

### What must be replaced or adapted

- SwiftUI and `NSWindow` are macOS-specific; replace the UI with a Windows-native framework.
- `launchd`, `.plist` files, `launchctl`, and the Bash installer are macOS-specific; replace them with Windows Task Scheduler and PowerShell.
- Replace macOS `Cmd + Enter` with the Windows convention `Ctrl + Enter`.
- Move the default log file from the repository directory to a stable per-user application-data directory. Writing user data into the source/install directory can fail due to permissions and can be lost during upgrades.

### Existing implementation gaps to address

1. The current Python `log` command always appends a new record. It does not enforce one entry per logical day. Decide whether multiple entries per day are permitted; do not imply that `has-logged` prevents duplicate writes.
2. `read_all_logs` skips malformed JSONL lines silently. Consider logging a warning to stderr with the line number.
3. Concurrent app launches could append at the same time. Use a single-instance UI and/or a file lock around writes.
4. The current default file path points at the repository root. Make the user-data location the default on Windows.
5. The current CLI accepts `--date` without validating the `YYYY-MM-DD` format. Validate explicit dates.
6. Define whether timestamps are local time or UTC. For compatibility, retain local ISO timestamps initially and document the choice; a future schema may store an explicit timezone/UTC timestamp.
7. Ensure the UI invokes Python with an argument list/process API rather than concatenating user text into a shell command.

## 3. Goals and non-goals

### Goals

- Native-feeling Windows desktop UI.
- Reliable scheduled prompt after sign-in, including catch-up after sleep or missed schedules.
- Local-only storage by default; no server and no open network ports.
- Preserve existing JSONL data shape where possible.
- Simple setup, status diagnostics, and uninstall.
- Automated tests for backend behavior and Windows scheduling integration.

### Non-goals for the first Windows release

- Cloud sync or accounts.
- AI-generated summaries.
- A database server.
- A cross-platform UI rewrite.
- Guaranteed execution while the computer is powered off. The application can catch up when Windows next runs the scheduled task and the user is signed in.

## 4. Recommended technology stack

| Layer | Recommendation | Reason |
|---|---|---|
| Desktop UI | C# with WPF on modern .NET (LTS version supported at implementation time) | Mature Windows desktop framework; supports keyboard handling, window positioning, and native integration |
| UI architecture | MVVM, using a small ViewModel and service interfaces | Keeps UI logic testable and separate from persistence/scheduling |
| Backend | Existing Python 3 CLI | Reuses tested business logic and minimizes porting risk |
| UI-to-backend IPC | Child process invocation with structured JSON over stdout/stderr | No local HTTP server, sockets, or ports required |
| Storage | JSON Lines file | Human-readable, portable, compatible with current records |
| Scheduling | Windows Task Scheduler | Native Windows scheduling and catch-up options |
| Installer/setup | PowerShell setup and uninstall scripts; optionally package later with MSIX or an installer tool | Replaces Bash and LaunchAgent setup |
| Tests | Python `unittest`; .NET test project for UI/service logic; manual or scripted Windows integration tests | Tests core logic separately from OS integration |
| Diagnostics | Rotating application log under `%LOCALAPPDATA%\DailyLogger\logs` | Useful when scheduled tasks or process launches fail |

**Alternative:** WinUI 3 is possible, but WPF is the recommended first implementation because this app needs a small, simple desktop window rather than a complex modern shell. Avoid maintaining both WPF and WinUI implementations.

## 5. High-level architecture

```text
                 Windows Task Scheduler
          (daily trigger + logon/catch-up policy)
                           |
                           v
               DailyLogger Windows Launcher
           (checks user session and daily status)
                           |
                           v
                  WPF Desktop Application
           (floating prompt, keyboard shortcuts)
                           |
                process invocation / JSON
                           |
                           v
                  Python CLI Backend
              (validate, date, read, append)
                           |
                           v
        %LOCALAPPDATA%\DailyLogger\daily_logs.txt
```

Supporting components:

```text
PowerShell installer
  ├── checks .NET runtime and Python
  ├── installs/copies app files
  ├── creates user-data/log directories
  ├── registers scheduled tasks
  └── runs a health check

Python unit tests ──> backend behavior
.NET tests ─────────> ViewModel and process wrapper
Windows smoke tests ─> scheduler, prompt, sleep/wake, uninstall
```

## 6. Component responsibilities

### 6.1 WPF desktop application

Responsibilities:

- Display the question “What did you do today?”
- Provide a multiline text editor and Save / Dismiss actions.
- Keep the window above ordinary windows when appropriate, without blocking secure/system UI.
- Center the prompt on the active monitor and handle DPI scaling and multiple monitors.
- Support `Ctrl + Enter` to save and dismiss.
- Support `Esc` to dismiss without saving.
- Avoid stealing focus repeatedly or reopening multiple prompt windows.
- Show clear save errors and preserve text if a save fails.
- Offer a manual “Open DailyLogger” action for testing and recovery.

Implementation notes:

- Use `Window.Topmost = true` only for the prompt while it is active; avoid a permanent topmost window.
- Use a named mutex or equivalent single-instance mechanism so a scheduled trigger and a manual launch do not open duplicate windows.
- Keep UI operations on the WPF dispatcher thread.
- The UI must not directly parse or modify the JSONL file; it should use the backend service wrapper.
- Do not execute user text through `cmd.exe` or PowerShell. Use `ProcessStartInfo` with `UseShellExecute = false` and an argument-list API, and pass text as a distinct argument or through stdin.

Suggested project layout:

```text
windows/
  DailyLogger.sln
  src/
    DailyLogger.App/
      App.xaml
      App.xaml.cs
      MainWindow.xaml
      MainWindow.xaml.cs
      ViewModels/
        PromptViewModel.cs
      Services/
        LoggerBackendClient.cs
        SingleInstanceService.cs
        AppPaths.cs
      Models/
        LogRecord.cs
  tests/
    DailyLogger.App.Tests/
```

### 6.2 Python backend

Keep `backend/logger.py` as the canonical business-logic layer initially.

Commands to preserve:

```powershell
python backend\logger.py log --text "Finished my assignment"
python backend\logger.py has-logged
python backend\logger.py list --limit 10 --reverse
```

The exact global `--file` argument placement should remain consistent with the current parser: it is defined before the subcommand.

Recommended refinements:

- Resolve the default path through `DAILY_LOG_FILE` first, then a Windows-specific `%LOCALAPPDATA%\DailyLogger\daily_logs.txt` path when running on Windows.
- Retain the current JSONL record fields: `id`, `timestamp`, `date`, and `entry`.
- Validate non-empty entry text and explicit dates.
- Return machine-readable JSON on stdout and diagnostic errors on stderr.
- Keep exit codes documented:
  - `0`: success; for `has-logged`, a matching entry exists.
  - `1`: no matching entry for `has-logged`, or an ordinary validation failure (prefer a distinct documented error code for failures in a later revision).
- Add a version/health command if useful for installer diagnostics.
- Ensure the backend creates the parent directory before writing.
- Consider a file lock around appends to protect against simultaneous CLI invocations.
- Preserve existing behavior that allows multiple records for the same logical date unless a deliberate product decision changes it.

### 6.3 Storage

Default location:

```text
%LOCALAPPDATA%\DailyLogger\daily_logs.txt
%LOCALAPPDATA%\DailyLogger\logs\
%LOCALAPPDATA%\DailyLogger\config.json
```

Use `%LOCALAPPDATA%` for per-user application data. Do not hardcode a username or install location.

Example JSONL record (one JSON object per line):

```json
{"id":"d2eb7c4d","timestamp":"2026-10-24T00:30:15","date":"2026-10-23","entry":"Finished my assignment"}
```

Storage rules:

- Append one complete JSON object and newline per record.
- Use UTF-8.
- Never rewrite the whole file merely to add a record.
- Avoid storing sensitive information in diagnostic logs.
- Consider backup/export and import tools as a later feature.
- If migration from an existing repository-root `daily_logs.txt` is offered, copy it only when the target file does not already exist, preserve the original, and report the migration result.

### 6.4 Windows scheduling

Replace `launchd` with Windows Task Scheduler.

Recommended first-release behavior:

1. Register a per-user scheduled task for the chosen daily time.
2. Configure “run as soon as possible after a scheduled start is missed” so a machine that was asleep or off can catch up when Windows next permits execution.
3. Use a logon trigger as a second opportunity to run the launcher and check whether today's prompt is still pending.
4. If adding a resume/unlock event trigger, treat it as an optional enhancement and test it on supported Windows versions. Do not rely on a resume event alone.
5. Before showing the prompt, check whether a log already exists for the current logical date.
6. Use a single-instance guard to prevent daily, logon, and manual triggers from creating duplicate windows.
7. Run in the interactive user's session. A task configured to run when the user is not logged on may not be able to show a visible WPF window.
8. Document that Windows cannot display a prompt while the computer is powered off, and that display timing depends on sign-in/session availability.

Use Task Scheduler's “run as soon as possible after a scheduled start is missed” setting rather than claiming that a daily trigger itself guarantees an exact wake-time launch.

Scheduling configuration should live in a per-user config file, for example:

```json
{
  "hour": 2,
  "minute": 0
}
```

Validate `hour` in `0..23` and `minute` in `0..59`. A PowerShell installer should update the scheduled task when the user changes the schedule.

**Logical date and schedule time are different concepts:** the prompt may trigger at 02:00, while an entry before 05:00 is attributed to the previous logical day. Keep that policy explicit and covered by tests.

### 6.5 Windows setup and uninstall

Replace `setup.sh` with PowerShell scripts:

```text
scripts/
  install.ps1
  uninstall.ps1
  status.ps1
  run-now.ps1
```

`install.ps1` should:

1. Check that Windows and the required .NET runtime/SDK are suitable for the selected deployment model.
2. Check Python availability or install/package a controlled Python runtime if distribution requirements justify it.
3. Build or install the WPF app.
4. Create `%LOCALAPPDATA%\DailyLogger\` and its logs directory.
5. Register the scheduled task with the chosen time and missed-run policy.
6. Run backend and app health checks.
7. Print the installed paths, task name, schedule, and troubleshooting instructions.

`uninstall.ps1` should remove the scheduled task and application binaries/configuration as appropriate, but **must not delete the user's logs by default**. Offer data deletion as a separate, explicit option.

For a public release, decide whether to ship a self-contained .NET app and how Python will be provided. A bundled Python runtime or packaged backend can make setup more predictable than requiring users to install Python manually.

## 7. Runtime flows

### 7.1 Scheduled prompt

1. Task Scheduler starts the launcher at the configured time.
2. The launcher verifies it is running in the interactive user session.
3. It acquires a single-instance lock.
4. It asks the Python backend whether an entry exists for the current logical date.
5. If already logged, it exits quietly or shows a non-intrusive status.
6. Otherwise, it opens the WPF prompt.
7. The user enters a reflection and presses `Ctrl + Enter` or clicks Save.
8. The UI invokes the Python `log` command.
9. The backend validates the input, computes the logical date, and appends a JSONL record.
10. The UI closes only after confirmed success; on failure, it displays an error and keeps the text available.

### 7.2 Dismiss without saving

1. The user presses `Esc` or clicks Dismiss.
2. The prompt closes without calling `log`.
3. No entry is created.
4. The next launch policy should be defined: avoid repeated intrusive prompts in a tight loop, but allow manual reopening. A later enhancement can track “dismissed today” separately from “logged today.”

### 7.3 Manual launch

1. User launches DailyLogger from Start Menu or `run-now.ps1`.
2. The same single-instance and `has-logged` checks apply.
3. If the prompt is already open, focus the existing window instead of creating another.
4. If already logged, provide a useful message or open the history view if implemented.

### 7.4 Catch-up after sleep or missed schedule

1. The scheduled task's missed-start policy or logon trigger starts the launcher after Windows becomes available.
2. The launcher checks the current logical date, not just whether the scheduled clock time has passed.
3. If the day is still pending, it opens the prompt.
4. Single-instance protection prevents duplicate prompts if more than one trigger fires.

## 8. Backend/UI process contract

The UI should call the backend using a process wrapper that:

- Uses a known Python executable and absolute script path.
- Uses a safe argument list; never builds a shell command from entry text.
- Sets `DAILY_LOG_FILE` or passes `--file` so storage location is explicit.
- Captures stdout and stderr.
- Applies a reasonable timeout and handles process launch failures.
- Parses JSON output and checks the exit code.
- Does not report success until the backend confirms that the write completed.

For longer text, stdin is a safer interface than command-line arguments. If using stdin, implement a clearly documented backend mode rather than relying on shell quoting.

Example conceptual response from a successful log command:

```json
{
  "status": "success",
  "record": {
    "id": "d2eb7c4d",
    "timestamp": "2026-10-24T00:30:15",
    "date": "2026-10-23",
    "entry": "Finished my assignment"
  }
}
```

## 9. Configuration and environment

Suggested configuration precedence:

1. Explicit CLI argument.
2. Environment variable, such as `DAILY_LOG_FILE`.
3. Per-user config file.
4. Safe per-user default under `%LOCALAPPDATA%\DailyLogger`.

Validate all values. Do not use `eval` to parse JSON or interpolate untrusted config into shell commands.

Document the chosen Python executable and installed app path. Scheduled tasks may have a different working directory and `PATH` than an interactive terminal, so use absolute paths.

## 10. Reliability, privacy, and security

- Local-first: no network access is needed for core functionality.
- Least privilege: run as the current user; do not request administrator rights unless the chosen installer genuinely requires them.
- Do not store logs in the application installation directory.
- Use safe subprocess invocation and validate CLI input.
- Protect against concurrent writes with a lock or serialized writer.
- Handle a missing Python runtime, corrupt config, malformed JSONL lines, and permission errors with understandable diagnostics.
- Never silently discard the user's unsaved text after a failed write.
- Keep logs local and avoid including reflection text in technical diagnostics.
- If packaging the Python backend, verify the packaged interpreter and backend files are from the intended release.
- Code-sign the Windows executable/installer for a public distribution when practical.

## 11. Testing strategy

### Python unit tests

Keep and extend `backend/test_logger.py`:

- Logical date at 00:00, 04:59, and 05:00.
- Empty text rejection.
- Unicode and multiline text.
- Explicit date validation.
- Append and list behavior.
- `has-logged` for empty and populated files.
- Missing file and missing parent directory.
- Malformed JSONL line behavior.
- Concurrent append behavior if supported.
- Environment-variable and Windows default-path resolution.

Run:

```powershell
python -m unittest backend.test_logger
```

### .NET tests

Test:

- ViewModel save/dismiss behavior.
- Correct `Ctrl + Enter` and Escape commands.
- Backend process argument construction.
- JSON success and error handling.
- Backend timeout and missing executable.
- Single-instance behavior.
- Save failure retains the user's text.

### Windows integration tests

Manually or automatically verify:

- Clean installation and upgrade.
- Scheduled launch while signed in.
- Missed schedule catch-up after sleep.
- Catch-up after reboot/logon.
- No duplicate window when triggers overlap.
- Multiple monitors and DPI scaling.
- Lock/unlock behavior if an unlock trigger is implemented.
- Uninstall preserves logs.
- No network listeners are created.
- Existing JSONL data remains readable.

## 12. Implementation phases

### Phase 1 — Make the backend Windows-safe

- Add a Windows per-user default data path.
- Validate dates and improve diagnostics.
- Add write locking if concurrent invocations are possible.
- Keep the current JSONL schema and CLI behavior.
- Run and expand the Python test suite.

**Exit criteria:** backend commands and tests work on Windows without macOS tooling.

### Phase 2 — Build the WPF prompt

- Create the .NET solution and WPF application.
- Implement the prompt, text input, Save, Dismiss, `Ctrl + Enter`, and Escape.
- Implement a safe Python process wrapper.
- Add a single-instance guard and error handling.

**Exit criteria:** manual launch can save and list entries using the existing Python backend.

### Phase 3 — Add scheduling

- Implement PowerShell Task Scheduler registration.
- Add daily trigger and missed-run catch-up behavior.
- Add logon check and single-instance handling.
- Implement status and run-now scripts.

**Exit criteria:** the prompt appears at the configured time or catches up when Windows becomes available, without duplicate windows.

### Phase 4 — Package and install

- Choose a supported .NET deployment model.
- Decide whether Python is a prerequisite or bundled.
- Implement installer, upgrade, and uninstall flows.
- Keep user data separate from application binaries.
- Add clear diagnostics and recovery instructions.

**Exit criteria:** a clean Windows machine can install and use the application through documented steps.

### Phase 5 — Release hardening

- Test scheduling across sleep, reboot, and sign-in scenarios.
- Test multiple monitors, DPI, and keyboard accessibility.
- Test large logs, malformed records, and write failures.
- Review privacy, signing, licensing, and update behavior.
- Update README with Windows instructions and supported versions.

**Exit criteria:** documented Windows release with repeatable installation and test results.

## 13. Definition of done

- [ ] Python backend runs on Windows.
- [ ] Existing JSONL records remain compatible.
- [ ] WPF prompt supports Save, Dismiss, `Ctrl + Enter`, and Escape.
- [ ] Save errors do not destroy typed text.
- [ ] Task Scheduler triggers and missed-run catch-up are tested.
- [ ] Logon and scheduled triggers do not create duplicate windows.
- [ ] Default data is stored under `%LOCALAPPDATA%\DailyLogger`.
- [ ] Installer, status, run-now, and uninstall scripts are documented.
- [ ] Uninstall preserves user logs by default.
- [ ] Python and .NET tests pass on a supported Windows machine.
- [ ] README explains setup, configuration, troubleshooting, and limitations.

## 14. Key decisions to keep explicit

1. **Keep Python or rewrite the backend?** Keep Python for the first Windows version. Reconsider only if packaging or deployment makes it impractical.
2. **WPF or WinUI 3?** Use WPF for the first port to reduce implementation complexity.
3. **One entry per day or multiple?** The current backend permits multiple entries. `has-logged` is a check, not a uniqueness constraint.
4. **What does “wake trigger” mean?** Use missed-run catch-up and logon checks; test resume/unlock triggers separately. Do not promise a visible prompt while Windows is off or before a user session is available.
5. **Where is data stored?** Use `%LOCALAPPDATA%\DailyLogger` by default, with explicit migration rather than silently relocating or overwriting existing data.
