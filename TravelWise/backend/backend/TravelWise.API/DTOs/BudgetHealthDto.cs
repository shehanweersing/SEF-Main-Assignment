namespace TravelWise.API.DTOs
{
    public sealed class BudgetHealthDto
    {
        public decimal TotalBudget { get; init; }
        public decimal TotalSpent { get; init; }
        public decimal RemainingBudget { get; init; }
        public decimal SpendingPercentage { get; init; }
        public string HealthStatus { get; init; } = "HEALTHY";
        public decimal BurnRatePerDay { get; init; }
        public decimal ProjectedSpend { get; init; }
        public decimal ForecastedShortfall { get; init; }
        public decimal ConfidenceScore { get; init; }
    }
}