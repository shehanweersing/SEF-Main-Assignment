using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using TravelWise.API.Data;
using TravelWise.API.Models.AI;

namespace TravelWise.API.Services.AI.Agents
{
    public class CollaborationAgent : IAiAgent<CollaborationAgentResponse>
    {
        private readonly IAiModelService _modelService;
        private readonly ApplicationDbContext _dbContext;

        public CollaborationAgent(IAiModelService modelService, ApplicationDbContext dbContext)
        {
            _modelService = modelService;
            _dbContext = dbContext;
        }

        public string AgentName => "Group Collaboration & Consensus Agent";

        public async Task<CollaborationAgentResponse> ExecuteAsync(Guid workflowId, int tripId, object context)
        {
            var members = await _dbContext.TripMembers.Where(m => m.TripId == tripId).ToListAsync();
            var preferences = await _dbContext.MemberPreferences.Where(p => p.TripId == tripId).ToListAsync();

            var prompt = $@"
You are the Group Collaboration & Consensus Agent.
Analyze the group member preferences and availability.
Members Count: {members.Count}
Preferences: {string.Join(", ", preferences.Select(p => $"UserId: {p.UserId}, Category: {p.Category}, Value: {p.PreferenceValue}"))}

Identify conflicting preferences, determine group priorities, and calculate consensus.
Provide constraints for the itinerary agent based on consensus.

Respond in JSON according to the CollaborationAgentResponse schema.
";

            var systemPrompt = "Return ONLY valid JSON matching the CollaborationAgentResponse schema.";

            var response = await _modelService.GenerateStructuredResponseAsync<CollaborationAgentResponse>(prompt, systemPrompt);

            // Deterministic validation
            if (response.ConsensusScore < 0 || response.ConsensusScore > 1)
            {
                response.ConsensusScore = Math.Clamp(response.ConsensusScore, 0, 1);
            }

            return response;
        }
    }
}
