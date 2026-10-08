using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace TravelWise.API.Services.AI
{
    public class AiModelService : IAiModelService
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<AiModelService> _logger;
        private readonly string _apiKey;

        public AiModelService(HttpClient httpClient, IConfiguration configuration, ILogger<AiModelService> logger)
        {
            _httpClient = httpClient;
            _logger = logger;
            _apiKey = configuration["GEMINI_API_KEY"] ?? Environment.GetEnvironmentVariable("GEMINI_API_KEY") ?? "MISSING_KEY";
        }

        public async Task<string> GenerateResponseAsync(string prompt, string? systemPrompt = null)
        {
            return await ExecuteGeminiRequestAsync(prompt, systemPrompt, false);
        }

        public async Task<T> GenerateStructuredResponseAsync<T>(string prompt, string? systemPrompt = null) where T : class
        {
            var jsonResponse = await ExecuteGeminiRequestAsync(prompt, systemPrompt, true);
            try
            {
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true, AllowTrailingCommas = true };
                return JsonSerializer.Deserialize<T>(jsonResponse, options) 
                    ?? throw new Exception("Failed to deserialize structured response.");
            }
            catch (JsonException ex)
            {
                _logger.LogError(ex, "Failed to parse AI model JSON response. Raw response: {Response}", jsonResponse);
                throw;
            }
        }

        private async Task<string> ExecuteGeminiRequestAsync(string prompt, string? systemPrompt, bool requireJson)
        {
            var endpoint = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={_apiKey}";

            var requestBody = new
            {
                system_instruction = systemPrompt != null ? new { parts = new[] { new { text = systemPrompt } } } : null,
                contents = new[]
                {
                    new
                    {
                        parts = new[] { new { text = prompt } }
                    }
                },
                generationConfig = requireJson ? new { responseMimeType = "application/json" } : null
            };

            var jsonRequest = JsonSerializer.Serialize(requestBody, new JsonSerializerOptions { DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull });
            var content = new StringContent(jsonRequest, Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync(endpoint, content);
            var responseString = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError("Gemini API Error: {StatusCode} - {Error}", response.StatusCode, responseString);
                throw new Exception($"AI Model API call failed with status {response.StatusCode}");
            }

            using var document = JsonDocument.Parse(responseString);
            var root = document.RootElement;
            
            try
            {
                var text = root.GetProperty("candidates")[0].GetProperty("content").GetProperty("parts")[0].GetProperty("text").GetString();
                return text ?? string.Empty;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to extract text from Gemini response. Raw: {Raw}", responseString);
                throw new Exception("Unexpected AI model response format.");
            }
        }
    }
}
