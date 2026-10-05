namespace TravelWise.API.DTOs
{
    public class CreateBudgetDto
    {
        public int TripId { get; set; }
        public decimal TotalAllocation { get; set; }
        public string Currency { get; set; } = "LKR";
    }

    public sealed class BudgetHealthRequest
    {
        public int? TripDurationDays { get; set; }
    }

    public class BudgetCategoryDto
    {
        public string Name { get; set; } = string.Empty;
        public decimal AllocatedAmount { get; set; }
    }

    public class CreateExpenseDto
    {
        public int BudgetId { get; set; }
        public string Category { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public DateTime ExpenseDate { get; set; }
    }
}