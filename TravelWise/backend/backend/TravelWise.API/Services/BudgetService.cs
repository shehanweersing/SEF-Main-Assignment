using Microsoft.EntityFrameworkCore;
using TravelWise.API.Data;
using TravelWise.API.DTOs;
using TravelWise.API.Models;
using TravelWise.API.Utilities;

namespace TravelWise.API.Services
{
    public class BudgetService
    {
        private readonly ApplicationDbContext _context;

        public BudgetService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<Expense> AddExpenseAsync(CreateExpenseDto dto)
        {
            if (dto.Amount <= 0)
                throw new ArgumentException("Expense amount must be greater than zero to pass BR-BUD-01.");

            var budget = await _context.Budgets.Include(item => item.Trip).Include(item => item.Expenses).Include(item => item.Categories)
                .SingleOrDefaultAsync(item => item.Id == dto.BudgetId)
                ?? throw new ArgumentException("The selected budget does not exist.");
            if (budget.Trip is null)
                throw new ArgumentException("The selected budget is not linked to a trip.");
            var tripCurrency = string.IsNullOrWhiteSpace(budget.Trip.Currency) ? "USD" : budget.Trip.Currency;
            if (!string.Equals(budget.Currency, tripCurrency, StringComparison.OrdinalIgnoreCase))
                throw new ArgumentException("Budget currency must match the trip currency to pass BR-BUD-05.");
            var category = budget.Categories.FirstOrDefault(item => item.Name.Equals(dto.Category.Trim(), StringComparison.OrdinalIgnoreCase));
            var categorySpent = budget.Expenses.Where(item => item.Category.Equals(dto.Category.Trim(), StringComparison.OrdinalIgnoreCase)).Sum(item => item.Amount);
            if (category is not null && categorySpent + dto.Amount > category.AllocatedAmount)
                throw new ArgumentException("This expense exceeds the remaining category budget.");
            if (budget.Expenses.Sum(expense => expense.Amount) + dto.Amount > budget.TotalAllocation)
                throw new ArgumentException("This expense exceeds the remaining budget.");
            if (string.IsNullOrWhiteSpace(dto.Category) || string.IsNullOrWhiteSpace(dto.Description))
                throw new ArgumentException("Category and description are required.");

            var expense = new Expense
            {
                BudgetId = dto.BudgetId,
                Category = dto.Category,
                Description = dto.Description,
                Amount = dto.Amount,
                ExpenseDate = DateTimeNormalization.ToUtc(dto.ExpenseDate)
            };

            _context.Expenses.Add(expense);
            await _context.SaveChangesAsync();
            return expense;
        }
    }
}