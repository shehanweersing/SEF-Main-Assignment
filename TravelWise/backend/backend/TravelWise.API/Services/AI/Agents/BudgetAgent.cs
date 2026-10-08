using System;
using System.Text.Json;
using System.Threading.Tasks;
using TravelWise.API.Data;
using TravelWise.API.Models.AI;
using TravelWise.API.Services;
using Microsoft.EntityFrameworkCore;
using System.Linq;

namespace TravelWise.API.Services.AI.Agents
{
    public class BudgetAgent : IAiAgent<BudgetAgentResponse>
    {
        private readonly IAiModelService _modelService;
        private readonly ApplicationDbContext _dbContext;

        public BudgetAgent(IAiModelService modelService, ApplicationDbContext dbContext)
        {
            _modelService = modelService;
            _dbContext = dbContext;
        }

        public string AgentName => "Budget Optimization Agent";

        public async Task<BudgetAgentResponse> ExecuteAsync(Guid workflowId, int tripId, object context)
        {
            // Gather context
            var budget = await _dbContext.Budgets
                .Include(b => b.Categories)
                .Include(b => b.Expenses)
                .FirstOrDefaultAsync(b => b.TripId == tripId);

            var activities = await _dbContext.Activities
                .Where(a => a.TripId == tripId)
                .ToListAsync();

            if (budget == null)
            {
                return new BudgetAgentResponse
                {
                    BudgetStatus = "NO_BUDGET",
                    Confidence = 1.0,
                    Reasoning = { "No budget has been set for this trip." }
                };
            }

            var prompt = $@"
You are the Budget Optimization Agent.
Your task is to analyze the financial feasibility of the trip and optimize spending.
Total Budget: {budget.TotalAmount}
Expenses Recorded: {string.Join(", ", budget.Expenses?.Select(e => $"{e.Description}: {e.Amount}") ?? Array.Empty<string>())}
Planned Activities: {string.Join(", ", activities.Select(a => $"{a.Title}: {a.Cost}"))}
Categories: {string.Join(", ", budget.Categories?.Select(c => $"{c.Name} (Allocated: {c.AllocatedAmount})") ?? Array.Empty<string>())}

Analyze this information and provide a JSON response following the schema.
Calculate the actual remaining amount and detect any overspending.
";
            
            var systemPrompt = "Return ONLY valid JSON matching the BudgetAgentResponse schema.";

            var response = await _modelService.GenerateStructuredResponseAsync<BudgetAgentResponse>(prompt, systemPrompt);

            // Deterministic backend validation here or handled by Orchestrator
            // We ensure math is correct
            response.TotalBudget = budget.TotalAmount;
            response.SpentAmount = budget.Expenses?.Sum(e => e.Amount) ?? 0;
            response.RemainingAmount = response.TotalBudget - response.SpentAmount;

            return response;
        }
    }
}
