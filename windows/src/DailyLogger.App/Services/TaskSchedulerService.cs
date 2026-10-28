using System;
using System.Diagnostics;
using System.IO;
using System.Text.Json;
using DailyLogger.App.Models;

namespace DailyLogger.App.Services
{
    public class TaskSchedulerService
    {
        public const string TaskName = "DailyLogger";

        public ScheduleConfig LoadConfig()
        {
            var configPath = AppPaths.ConfigFilePath;
            if (File.Exists(configPath))
            {
                try
                {
                    var json = File.ReadAllText(configPath);
                    var cfg = JsonSerializer.Deserialize<ScheduleConfig>(json);
                    if (cfg != null) return cfg;
                }
                catch
                {
                    // Fall back to default
                }
            }
            return new ScheduleConfig { Hour = 2, Minute = 0 };
        }

        public void SaveConfig(ScheduleConfig config)
        {
            var configPath = AppPaths.ConfigFilePath;
            var json = JsonSerializer.Serialize(config, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(configPath, json);
        }

        public bool RegisterTask(int? hour = null, int? minute = null)
        {
            var config = LoadConfig();
            if (hour.HasValue) config.Hour = hour.Value;
            if (minute.HasValue) config.Minute = minute.Value;
            SaveConfig(config);

            var exePath = Process.GetCurrentProcess().MainModule?.FileName 
                ?? Path.Combine(AppContext.BaseDirectory, "DailyLogger.App.exe");

            var timeStr = $"{config.Hour:D2}:{config.Minute:D2}";

            // Register daily scheduled task with schtasks.exe
            // /SC DAILY /ST HH:MM /RI (repetition)
            var createArgs = $"/Create /TN \"{TaskName}\" /TR \"\\\"{exePath}\\\"\" /SC DAILY /ST {timeStr} /F";

            var psi = new ProcessStartInfo
            {
                FileName = "schtasks.exe",
                Arguments = createArgs,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            try
            {
                using var proc = Process.Start(psi);
                proc?.WaitForExit(5000);

                // Also create Start Menu Shortcut
                CreateStartMenuShortcut(exePath);

                return proc?.ExitCode == 0;
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Failed to register scheduled task: {ex.Message}");
                return false;
            }
        }

        public bool UnregisterTask()
        {
            var psi = new ProcessStartInfo
            {
                FileName = "schtasks.exe",
                Arguments = $"/Delete /TN \"{TaskName}\" /F",
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            try
            {
                using var proc = Process.Start(psi);
                proc?.WaitForExit(5000);

                RemoveStartMenuShortcut();
                return proc?.ExitCode == 0;
            }
            catch
            {
                return false;
            }
        }

        public bool IsTaskRegistered()
        {
            var psi = new ProcessStartInfo
            {
                FileName = "schtasks.exe",
                Arguments = $"/Query /TN \"{TaskName}\"",
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            try
            {
                using var proc = Process.Start(psi);
                proc?.WaitForExit(5000);
                return proc?.ExitCode == 0;
            }
            catch
            {
                return false;
            }
        }

        private static void CreateStartMenuShortcut(string targetExe)
        {
            try
            {
                var programs = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                    @"Microsoft\Windows\Start Menu\Programs");
                var shortcutPath = Path.Combine(programs, "DailyLogger.lnk");

                // PowerShell one-liner to create shortcut without COM reference issues
                var psScript = $"$s=(New-Object -COM WScript.Shell).CreateShortcut('{shortcutPath}');$s.TargetPath='{targetExe}';$s.WorkingDirectory='{Path.GetDirectoryName(targetExe)}';$s.Description='DailyLogger - Distraction-free daily reflection';$s.Save()";
                
                var psi = new ProcessStartInfo
                {
                    FileName = "powershell.exe",
                    Arguments = $"-NoProfile -ExecutionPolicy Bypass -Command \"{psScript}\"",
                    UseShellExecute = false,
                    CreateNoWindow = true
                };
                using var proc = Process.Start(psi);
                proc?.WaitForExit(3000);
            }
            catch
            {
                // Non-fatal
            }
        }

        private static void RemoveStartMenuShortcut()
        {
            try
            {
                var programs = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                    @"Microsoft\Windows\Start Menu\Programs");
                var shortcutPath = Path.Combine(programs, "DailyLogger.lnk");
                if (File.Exists(shortcutPath))
                {
                    File.Delete(shortcutPath);
                }
            }
            catch
            {
                // Non-fatal
            }
        }
    }
}
