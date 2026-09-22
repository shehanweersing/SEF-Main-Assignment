using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TravelWise.API.Data;
using TravelWise.API.DTOs;

namespace TravelWise.API.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/Budgets")]
    public sealed class BudgetsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public BudgetsController(ApplicationDbContext context) => _context = context;

        [HttpGet("{tripId:int}/health")]
        public async Task<ActionResult<BudgetHealthDto>> GetHealth(int tripId)
        {
            var tripExists = await _context.Trips.AnyAsync(trip => trip.Id == tripId);
            if (!tripExists) return NotFound("The selected trip does not exist.");

            var totalBudget = await _context.Budgets
                .Where(budget => budget.TripId == tripId)
                .SumAsync(budget => (decimal?)budget.TotalAllocation) ?? 0m;

            var totalSpent = await _context.Expenses
                .Where(expense => expense.Budget != null && expense.Budget.TripId == tripId)
                .SumAsync(expense => (decimal?)expense.Amount) ?? 0m;

            var spendingPercentage = totalBudget > 0m
                ? decimal.Round(totalSpent / totalBudget * 100m, 2)
                : totalSpent > 0m ? 100m : 0m;

            var healthStatus = spendingPercentage <= 80m
                ? "HEALTHY"
                : spendingPercentage <= 100m
                    ? "WARNING"
                    : "CRITICAL";

            return Ok(new BudgetHealthDto
            {
                TotalBudget = decimal.Round(totalBudget, 2),
                TotalSpent = decimal.Round(totalSpent, 2),
                RemainingBudget = decimal.Round(totalBudget - totalSpent, 2),
                SpendingPercentage = spendingPercentage,
                HealthStatus = healthStatus,
            });
        }
    }
}