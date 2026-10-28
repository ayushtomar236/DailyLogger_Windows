using System;
using System.Text.Json.Serialization;

namespace DailyLogger.App.Models
{
    public class LogRecord
    {
        [JsonPropertyName("id")]
        public string Id { get; set; } = Guid.NewGuid().ToString("n")[..8];

        [JsonPropertyName("timestamp")]
        public string Timestamp { get; set; } = DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss");

        [JsonPropertyName("date")]
        public string Date { get; set; } = string.Empty;

        [JsonPropertyName("entry")]
        public string Entry { get; set; } = string.Empty;
    }
}
