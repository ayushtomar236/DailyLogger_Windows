using System;
using System.IO;
using System.Windows;
using DailyLogger.App.Services;
using DailyLogger.App.ViewModels;

namespace DailyLogger.App
{
    public partial class App : Application
    {
        private SingleInstanceService? _singleInstance;

        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);

            var logService = new LogService();
            var schedulerService = new TaskSchedulerService();

            var args = e.Args;

            // Handle CLI switches
            if (args.Length > 0)
            {
                var cmd = args[0].ToLowerInvariant();
                switch (cmd)
                {
                    case "--setup":
                    case "/setup":
                    case "-s":
                        int? hour = null;
                        int? minute = null;
                        if (args.Length > 1 && int.TryParse(args[1], out var h)) hour = h;
                        if (args.Length > 2 && int.TryParse(args[2], out var m)) minute = m;

                        var success = schedulerService.RegisterTask(hour, minute);
                        Console.WriteLine(success ? "DailyLogger task registered successfully." : "Failed to register DailyLogger task.");
                        Shutdown(success ? 0 : 1);
                        return;

                    case "--uninstall":
                    case "/uninstall":
                    case "-u":
                        var removed = schedulerService.UnregisterTask();
                        Console.WriteLine(removed ? "DailyLogger task uninstalled successfully." : "Failed to unregister DailyLogger task.");
                        Shutdown(removed ? 0 : 1);
                        return;

                    case "--status":
                    case "/status":
                        var isRegistered = schedulerService.IsTaskRegistered();
                        var hasLogged = logService.HasLoggedToday();
                        var logs = logService.ReadLogs();

                        Console.WriteLine($"[DailyLogger Status]");
                        Console.WriteLine($"Scheduled Task: {(isRegistered ? "Active" : "Not Registered")}");
                        Console.WriteLine($"Logged Today:   {(hasLogged ? "Yes" : "No")}");
                        Console.WriteLine($"Total Entries:  {logs.Count}");
                        Console.WriteLine($"Log File:       {AppPaths.LogFilePath}");
                        Shutdown(0);
                        return;
                }
            }

            // Normal UI launch: Enforce Single Instance
            _singleInstance = new SingleInstanceService();
            if (!_singleInstance.TryAcquire())
            {
                SingleInstanceService.ActivateExistingWindow();
                Shutdown(0);
                return;
            }

            var viewModel = new PromptViewModel(logService, schedulerService);
            var mainWindow = new MainWindow(viewModel);
            mainWindow.Show();
        }

        protected override void OnExit(ExitEventArgs e)
        {
            _singleInstance?.Dispose();
            base.OnExit(e);
        }
    }
}
