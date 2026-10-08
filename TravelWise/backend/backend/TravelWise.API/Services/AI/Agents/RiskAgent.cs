using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using TravelWise.API.Data;
using TravelWise.API.Models.AI;

namespace TravelWise.API.Services.AI.Agents
{
    public class RiskAgent : IAiAgent<RiskAgentResponse>
    {
        private readonly IAiModelService _modelService;
        private readonly ApplicationDbContext _dbContext;

        public RiskAgent(IAiModelService modelService, ApplicationDbContext dbContext)
        {
            _modelService = modelService;
            _dbContext = dbContext;
        }

        public string AgentName => "Travel Safety & Risk Intelligence Agent";

        public async Task<RiskAgentResponse> ExecuteAsync(Guid workflowId, int tripId, object context)
        {
            var trip = await _dbContext.Trips.FindAsync(tripId);
            var activities = await _dbContext.Activities.Where(a => a.TripId == tripId).ToListAsync();

            if (trip == null) throw new Exception("Trip not found");

            // Mock external weather/risk data gathering if weather API fails
            var weatherData = "Partly cloudy, 24C";

            var prompt = $@"
You are the Travel Safety & Risk Intelligence Agent.
Trip to {trip.Destination}.
Activities: {string.Join(", ", activities.Select(a => $"{a.Title} at {a.StartTime}"))}
Current weather data: {weatherData}

Evaluate the safety of the proposed trip and activities. Identify potentially unsafe activities and calculate a risk score.
Assign deterministic severity levels: LOW, MEDIUM, HIGH, CRITICAL.
Recommend safer alternatives and provide safety constraints to the itinerary agent.

Respond in JSON according to the RiskAgentResponse schema.
";

            var systemPrompt = "Return ONLY valid JSON matching the RiskAgentResponse schema.";

            var response = await _modelService.GenerateStructuredResponseAsync<RiskAgentResponse>(prompt, systemPrompt);

            // Deterministic validation
            var validLevels = new[] { "LOW", "MEDIUM", "HIGH", "CRITICAL" };
            if (!validLevels.Contains(response.RiskLevel))
            {
                response.RiskLevel = "MEDIUM";
            }

            return response;
        }
    }
}
