# Tasks

## 1. Packaging Structure & Bundling Automation

- [x] 1.1 Create the distribution scaffolding and staging directory structure (`scripts/`, `package/`) and verify the folder layout exists.
- [x] 1.2 Implement the release bundling script (`build-package.ps1`) that stages self-contained .NET binaries and an embedded Python runtime into `package/bin` and `package/runtime/python`, and verify staged executables run properly.

## 2. Installation Scripts

- [x] 2.1 Implement `scripts/install.ps1` to create target directories under `%LOCALAPPDATA%\Programs\DailyLogger` and `%LOCALAPPDATA%\DailyLogger\logs` and copy application files, verifying successful copy without administrative elevation.
- [x] 2.2 Add Windows Task Scheduler task registration to `scripts/install.ps1` (daily trigger, logon trigger, and `StartWhenAvailable` catch-up policy), and verify the task registers and is queryable via `Get-ScheduledTask -TaskName DailyLogger`.
- [x] 2.3 Add Start Menu shortcut creation to `scripts/install.ps1`, and verify the shortcut appears in the user's Start Menu programs directory pointing to the installed app.
- [x] 2.4 Create `install.cmd` batch runner executing `powershell.exe -ExecutionPolicy Bypass -NoProfile -File scripts\install.ps1`, and verify double-clicking or invoking `install.cmd` completes installation without execution policy errors.

## 3. Uninstallation and Diagnostics

- [x] 3.1 Implement `scripts/uninstall.ps1` to deregister the scheduled task, remove Start Menu shortcuts, and delete installed binaries while preserving `%LOCALAPPDATA%\DailyLogger\daily_logs.txt`, and verify uninstallation preserves user logs.
- [x] 3.2 Create `uninstall.cmd` batch runner executing `scripts/uninstall.ps1` with execution policy bypass, and verify running it cleans up the application and task.
- [x] 3.3 Implement `scripts/status.ps1` and `status.cmd` to report installation state, Task Scheduler status, and log file locations, and verify output reflects actual system status.
- [x] 3.4 Create `run-now.cmd` to launch the DailyLogger application on demand, and verify it starts the prompt when invoked.

## 4. Documentation & Verification

- [x] 4.1 Update documentation in `README.md` with one-click installation, diagnostic checks, and uninstallation instructions, and verify instructions match script behaviors.
- [x] 4.2 Perform an end-to-end installation, status verification, run-now test, and uninstallation cycle, and verify all operations succeed and leave user data intact.
