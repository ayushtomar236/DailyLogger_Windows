using System.Text.Json.Serialization;

namespace DailyLogger.App.Models
{
    public class ScheduleConfig
    {
        [JsonPropertyName("hour")]
        public int Hour { get; set; } = 2;

        [JsonPropertyName("minute")]
        public int Minute { get; set; } = 0;
    }
}
