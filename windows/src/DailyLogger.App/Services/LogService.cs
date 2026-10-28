using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using DailyLogger.App.Models;

namespace DailyLogger.App.Services
{
    public class LogService
    {
        private static readonly object _fileLock = new();

        public string CalculateLogicalDate(DateTime? now = null)
        {
            var dt = now ?? DateTime.Now;
            var target = dt.Hour < 5 ? dt.Date.AddDays(-1) : dt.Date;
            return target.ToString("yyyy-MM-dd");
        }

        public List<LogRecord> ReadLogs(string? filePath = null)
        {
            var path = filePath ?? AppPaths.LogFilePath;
            if (!File.Exists(path))
            {
                return new List<LogRecord>();
            }

            var records = new List<LogRecord>();
            lock (_fileLock)
            {
                using var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
                using var reader = new StreamReader(stream, Encoding.UTF8);

                string? line;
                while ((line = reader.ReadLine()) != null)
                {
                    line = line.Trim();
                    if (string.IsNullOrWhiteSpace(line)) continue;

                    try
                    {
                        var record = JsonSerializer.Deserialize<LogRecord>(line);
                        if (record != null)
                        {
                            records.Add(record);
                        }
                    }
                    catch
                    {
                        // Ignore malformed line to preserve readability of remaining logs
                    }
                }
            }

            return records;
        }

        public LogRecord AppendLog(string text, string? explicitDate = null, string? filePath = null)
        {
            var trimmed = text.Trim();
            if (string.IsNullOrWhiteSpace(trimmed))
            {
                throw new ArgumentException("Reflection entry cannot be empty.", nameof(text));
            }

            var now = DateTime.Now;
            var dateStr = explicitDate ?? CalculateLogicalDate(now);

            var record = new LogRecord
            {
                Id = Guid.NewGuid().ToString("n")[..8],
                Timestamp = now.ToString("yyyy-MM-ddTHH:mm:ss"),
                Date = dateStr,
                Entry = trimmed
            };

            var path = filePath ?? AppPaths.LogFilePath;
            var parentDir = Path.GetDirectoryName(path);
            if (!string.IsNullOrEmpty(parentDir) && !Directory.Exists(parentDir))
            {
                Directory.CreateDirectory(parentDir);
            }

            var jsonLine = JsonSerializer.Serialize(record) + Environment.NewLine;
            var bytes = Encoding.UTF8.GetBytes(jsonLine);

            lock (_fileLock)
            {
                using var stream = new FileStream(path, FileMode.Append, FileAccess.Write, FileShare.Read);
                stream.Write(bytes, 0, bytes.Length);
                stream.Flush();
            }

            return record;
        }

        public bool HasLoggedToday(string? filePath = null)
        {
            var today = CalculateLogicalDate();
            var logs = ReadLogs(filePath);
            return logs.Any(r => r.Date == today);
        }

        public List<LogRecord> GetRecentLogs(int limit = 5, string? filePath = null)
        {
            var logs = ReadLogs(filePath);
            logs.Reverse();
            return logs.Take(limit).ToList();
        }
    }
}
