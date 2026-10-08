using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using TravelWise.API.Data;
using TravelWise.API.Models.AI;

namespace TravelWise.API.Services.AI.Agents
{
    public class ItineraryAgent : IAiAgent<ItineraryAgentResponse>
    {
        private readonly IAiModelService _modelService;
        private readonly ApplicationDbContext _dbContext;

        public ItineraryAgent(IAiModelService modelService, ApplicationDbContext dbContext)
        {
            _modelService = modelService;
            _dbContext = dbContext;
        }

        public string AgentName => "Intelligent Itinerary Agent";

        public async Task<ItineraryAgentResponse> ExecuteAsync(Guid workflowId, int tripId, object context)
        {
            var trip = await _dbContext.Trips.FindAsync(tripId);
            var activities = await _dbContext.Activities.Where(a => a.TripId == tripId).ToListAsync();

            if (trip == null) throw new Exception("Trip not found");

            var prompt = $@"
You are the Intelligent Itinerary Agent.
Trip: {trip.Destination} from {trip.StartDate:yyyy-MM-dd} to {trip.EndDate:yyyy-MM-dd}.
Activities: {string.Join(", ", activities.Select(a => $"{a.Title} (Time: {a.StartTime} - {a.EndTime})"))}
Feedback/Constraints: {context}

Optimize the itinerary. Avoid overlapping activities. Recommend alternatives if there are conflicts.
Respond in JSON according to the provided schema.
";

            var systemPrompt = "Return ONLY valid JSON matching the ItineraryAgentResponse schema.";
            
            var response = await _modelService.GenerateStructuredResponseAsync<ItineraryAgentResponse>(prompt, systemPrompt);

            return response;
        }
    }
}
