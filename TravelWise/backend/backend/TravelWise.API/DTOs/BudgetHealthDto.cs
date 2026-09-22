namespace TravelWise.API.DTOs
{
    public sealed class BudgetHealthDto
    {
        public decimal TotalBudget { get; init; }
        public decimal TotalSpent { get; init; }
        public decimal RemainingBudget { get; init; }
        public decimal SpendingPercentage { get; init; }
        public string HealthStatus { get; init; } = "HEALTHY";
    }
}