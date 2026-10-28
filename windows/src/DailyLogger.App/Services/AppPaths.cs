using System;
using System.IO;

namespace DailyLogger.App.Services
{
    public static class AppPaths
    {
        public static string AppDataDirectory
        {
            get
            {
                var localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                var dir = Path.Combine(localAppData, "DailyLogger");
                if (!Directory.Exists(dir))
                {
                    Directory.CreateDirectory(dir);
                }
                return dir;
            }
        }

        public static string LogFilePath
        {
            get
            {
                var envPath = Environment.GetEnvironmentVariable("DAILY_LOG_FILE");
                if (!string.IsNullOrWhiteSpace(envPath))
                {
                    return envPath;
                }
                return Path.Combine(AppDataDirectory, "daily_logs.txt");
            }
        }

        public static string ConfigFilePath => Path.Combine(AppDataDirectory, "config.json");

        public static string LogsDirectory
        {
            get
            {
                var dir = Path.Combine(AppDataDirectory, "logs");
                if (!Directory.Exists(dir))
                {
                    Directory.CreateDirectory(dir);
                }
                return dir;
            }
        }
    }
}
