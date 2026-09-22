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