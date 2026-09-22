using System.Net.Http.Json;
using System.Text.Json.Serialization;
using TravelWise.API.DTOs;

namespace TravelWise.API.Services
{
    public sealed class WeatherTelemetryService
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<WeatherTelemetryService> _logger;

        public WeatherTelemetryService(HttpClient httpClient, ILogger<WeatherTelemetryService> logger)
        {
            _httpClient = httpClient;
            _logger = logger;
        }

        public async Task<WeatherTelemetryDto> GetWeatherAsync(string destination, CancellationToken cancellationToken = default)
        {
            var requestedDestination = string.IsNullOrWhiteSpace(destination) ? "Sri Lanka" : destination.Trim();
            try
            {
                using var geocodeResponse = await _httpClient.GetAsync($"https://geocoding-api.open-meteo.com/v1/search?name={Uri.EscapeDataString(requestedDestination)}&count=1&language=en&format=json", cancellationToken);
                geocodeResponse.EnsureSuccessStatusCode();
                var location = await geocodeResponse.Content.ReadFromJsonAsync<GeocodingResponse>(cancellationToken: cancellationToken);
                var place = location?.Results?.FirstOrDefault();
                if (place is null) return SeasonalFallback(requestedDestination, "Open-Meteo could not locate this destination.");

                using var forecastResponse = await _httpClient.GetAsync($"https://api.open-meteo.com/v1/forecast?latitude={place.Latitude}&longitude={place.Longitude}&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&timezone=auto", cancellationToken);
                forecastResponse.EnsureSuccessStatusCode();
                var forecast = await forecastResponse.Content.ReadFromJsonAsync<ForecastResponse>(cancellationToken: cancellationToken);
                if (forecast?.Current is null) return SeasonalFallback(requestedDestination, "Live weather was unavailable.");

                var summary = DescribeCode(forecast.Current.WeatherCode);
                return new WeatherTelemetryDto
                {
                    Destination = place.Name ?? requestedDestination,
                    Source = "Open-Meteo live telemetry",
                    TemperatureC = forecast.Current.TemperatureC,
                    RelativeHumidity = forecast.Current.RelativeHumidity,
                    WindSpeedKmh = forecast.Current.WindSpeedKmh,
                    WeatherCode = forecast.Current.WeatherCode,
                    Summary = summary,
                    Advisory = BuildAdvisory(forecast.Current.WeatherCode, forecast.Current.WindSpeedKmh),
                    RetrievedAtUtc = DateTime.UtcNow,
                };
            }
            catch (Exception exception) when (exception is HttpRequestException or TaskCanceledException or InvalidOperationException or System.Text.Json.JsonException)
            {
                _logger.LogWarning(exception, "Open-Meteo unavailable for {Destination}; using seasonal fallback", requestedDestination);
                return SeasonalFallback(requestedDestination, "Live weather is temporarily unavailable.");
            }
        }

        private static WeatherTelemetryDto SeasonalFallback(string destination, string reason)
        {
            var month = DateTime.UtcNow.Month;
            var isWetSeason = month is >= 5 and <= 10;
            return new WeatherTelemetryDto
            {
                Destination = destination,
                Source = "Seasonal climate estimate",
                IsFallback = true,
                TemperatureC = isWetSeason ? 27m : 29m,
                RelativeHumidity = isWetSeason ? 82m : 72m,
                WindSpeedKmh = isWetSeason ? 18m : 11m,
                Summary = isWetSeason ? "Warm with seasonal showers" : "Warm and mostly settled",
                Advisory = $"{reason} Planning estimate: pack light rain protection and check local advisories before departure.",
                RetrievedAtUtc = DateTime.UtcNow,
            };
        }

        private static string BuildAdvisory(int weatherCode, decimal windSpeed) => weatherCode switch
        {
            >= 95 => "Thunderstorms are possible. Recheck conditions before outdoor activities.",
            >= 80 => "Rain showers are possible. Keep flexible plans and light rain protection nearby.",
            _ when windSpeed >= 35 => "Strong winds are present. Take care with exposed routes and water activities.",
            _ => "Conditions look comfortable. Continue checking local advisories for trip-specific risks.",
        };

        private static string DescribeCode(int code) => code switch
        {
            0 => "Clear sky",
            <= 3 => "Partly cloudy",
            <= 48 => "Foggy",
            <= 67 => "Rain showers",
            <= 77 => "Snow conditions",
            <= 82 => "Rain showers",
            _ => "Thunderstorms",
        };

        private sealed class GeocodingResponse { [JsonPropertyName("results")] public List<Location>? Results { get; set; } }
        private sealed class Location { [JsonPropertyName("name")] public string? Name { get; set; } [JsonPropertyName("latitude")] public decimal Latitude { get; set; } [JsonPropertyName("longitude")] public decimal Longitude { get; set; } }
        private sealed class ForecastResponse { [JsonPropertyName("current")] public CurrentWeather? Current { get; set; } }
        private sealed class CurrentWeather { [JsonPropertyName("temperature_2m")] public decimal TemperatureC { get; set; } [JsonPropertyName("relative_humidity_2m")] public decimal RelativeHumidity { get; set; } [JsonPropertyName("wind_speed_10m")] public decimal WindSpeedKmh { get; set; } [JsonPropertyName("weather_code")] public int WeatherCode { get; set; } }
    }
}