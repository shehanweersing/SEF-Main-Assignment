using System.Threading.Tasks;
using System.Text.Json;

namespace TravelWise.API.Services.AI
{
    public interface IAiModelService
    {
        Task<string> GenerateResponseAsync(string prompt, string? systemPrompt = null);
        Task<T> GenerateStructuredResponseAsync<T>(string prompt, string? systemPrompt = null) where T : class;
    }
}
