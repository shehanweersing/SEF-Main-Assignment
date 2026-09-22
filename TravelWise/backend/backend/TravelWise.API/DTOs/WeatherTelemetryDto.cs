namespace TravelWise.API.DTOs
{
    public sealed class WeatherTelemetryDto
    {
        public string Destination { get; init; } = string.Empty;
        public string Source { get; init; } = "Seasonal estimate";
        public bool IsFallback { get; init; }
        public decimal? TemperatureC { get; init; }
        public decimal? RelativeHumidity { get; init; }
        public decimal? WindSpeedKmh { get; init; }
        public int? WeatherCode { get; init; }
        public string Summary { get; init; } = string.Empty;
        public string Advisory { get; init; } = string.Empty;
        public DateTime RetrievedAtUtc { get; init; } = DateTime.UtcNow;
    }
}