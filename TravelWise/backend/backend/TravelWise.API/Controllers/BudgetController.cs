using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TravelWise.API.Data;
using TravelWise.API.DTOs;
using TravelWise.API.Models;
using TravelWise.API.Services;
using TravelWise.API.Utilities;

namespace TravelWise.API.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class BudgetController : ControllerBase
    {
        private readonly BudgetService _budgetService;
        private readonly ApplicationDbContext _context;

        public BudgetController(BudgetService budgetService, ApplicationDbContext context)
        {
            _budgetService = budgetService;
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetBudgets([FromQuery] int? tripId) => Ok(await _context.Budgets.Include(b => b.Expenses).Where(b => !tripId.HasValue || b.TripId == tripId).ToListAsync());

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetBudget(int id) => await _context.Budgets.Include(b => b.Expenses).FirstOrDefaultAsync(b => b.Id == id) is { } budget ? Ok(budget) : NotFound();

        [HttpPost]
        public async Task<IActionResult> AddBudget([FromBody] CreateBudgetDto dto)
        {
            if (dto.TotalAllocation <= 0) return BadRequest("Total allocation must be greater than zero.");
            var trip = await _context.Trips.FindAsync(dto.TripId);
            if (trip is null) return NotFound("The selected trip does not exist.");
            var requestedCurrency = dto.Currency?.Trim().ToUpperInvariant();
            var tripCurrency = string.IsNullOrWhiteSpace(trip.Currency) ? "USD" : trip.Currency.Trim().ToUpperInvariant();
            if (string.IsNullOrWhiteSpace(requestedCurrency)) requestedCurrency = tripCurrency;
            if (!string.Equals(requestedCurrency, tripCurrency, StringComparison.OrdinalIgnoreCase)) return BadRequest("Budget currency must match the trip currency.");
            var budget = new Budget { TripId = dto.TripId, TotalAllocation = dto.TotalAllocation, Currency = requestedCurrency };
            _context.Budgets.Add(budget);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetBudget), new { id = budget.Id }, budget);
        }

        [HttpPost("~/api/trips/{tripId:int}/budget")]
        public Task<IActionResult> CreateTripBudget(int tripId, [FromBody] CreateBudgetDto dto)
        {
            dto.TripId = tripId;
            return AddBudget(dto);
        }

        [HttpGet("~/api/trips/{tripId:int}/budget")]
        public async Task<IActionResult> GetTripBudget(int tripId)
        {
            var budget = await _context.Budgets.Include(item => item.Expenses).SingleOrDefaultAsync(item => item.TripId == tripId);
            return budget is null ? NotFound() : Ok(budget);
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> UpdateBudget(int id, [FromBody] CreateBudgetDto dto) { var budget = await _context.Budgets.FindAsync(id); if (budget is null) return NotFound(); if (dto.TotalAllocation <= 0) return BadRequest("Total allocation must be greater than zero."); var trip = await _context.Trips.FindAsync(dto.TripId); if (trip is null) return NotFound("The selected trip does not exist."); var tripCurrency = string.IsNullOrWhiteSpace(trip.Currency) ? "USD" : trip.Currency; if (!string.Equals(dto.Currency, tripCurrency, StringComparison.OrdinalIgnoreCase)) return BadRequest("Budget currency must match the trip currency."); budget.TripId = dto.TripId; budget.TotalAllocation = dto.TotalAllocation; budget.Currency = dto.Currency.ToUpperInvariant(); await _context.SaveChangesAsync(); return Ok(budget); }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteBudget(int id) { var budget = await _context.Budgets.FindAsync(id); if (budget is null) return NotFound(); _context.Budgets.Remove(budget); await _context.SaveChangesAsync(); return NoContent(); }

        [HttpGet("expenses")]
        public async Task<IActionResult> GetExpenses([FromQuery] int? budgetId, [FromQuery] string? category, [FromQuery] int page = 1, [FromQuery] int pageSize = 25)
        {
            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 100);
            var query = _context.Expenses.AsNoTracking().Where(e => !budgetId.HasValue || e.BudgetId == budgetId);
            if (!string.IsNullOrWhiteSpace(category)) query = query.Where(e => e.Category == category);
            var total = await query.CountAsync();
            var items = await query.OrderByDescending(e => e.ExpenseDate).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
            return Ok(new { items, total, page, pageSize });
        }

        [HttpGet("expenses/{id:int}")]
        public async Task<IActionResult> GetExpense(int id) => await _context.Expenses.FindAsync(id) is { } expense ? Ok(expense) : NotFound();

        [HttpPost("expenses")]
        public async Task<IActionResult> AddExpense([FromBody] CreateExpenseDto dto)
        {
            try
            {
                if (!await _context.Budgets.AnyAsync(b => b.Id == dto.BudgetId)) return BadRequest("The selected budget does not exist.");
                var expense = await _budgetService.AddExpenseAsync(dto);
                return CreatedAtAction(nameof(AddExpense), new { id = expense.Id }, expense);
            }

            catch (ArgumentException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPost("~/api/budgets/{budgetId:int}/expenses")]
        public Task<IActionResult> CreateBudgetExpense(int budgetId, [FromBody] CreateExpenseDto dto)
        {
            dto.BudgetId = budgetId;
            return AddExpense(dto);
        }

        [HttpGet("~/api/budgets/{budgetId:int}/expenses")]
        public Task<IActionResult> ListBudgetExpenses(int budgetId, [FromQuery] string? category, [FromQuery] int page = 1, [FromQuery] int pageSize = 25) =>
            GetExpenses(budgetId, category, page, pageSize);

        [HttpPut("expenses/{id:int}")]
        [HttpPut("~/api/expenses/{id:int}")]
        public async Task<IActionResult> UpdateExpense(int id, [FromBody] CreateExpenseDto dto)
        {
            var expense = await _context.Expenses.Include(item => item.Budget).ThenInclude(item => item!.Expenses).SingleOrDefaultAsync(item => item.Id == id);
            if (expense is null) return NotFound();
            if (dto.Amount <= 0) return BadRequest("Expense amount must be greater than zero.");
            if (string.IsNullOrWhiteSpace(dto.Category) || string.IsNullOrWhiteSpace(dto.Description)) return BadRequest("Category and description are required.");
            var targetBudget = await _context.Budgets.Include(item => item.Expenses).Include(item => item.Categories).SingleOrDefaultAsync(item => item.Id == dto.BudgetId);
            if (targetBudget is null) return BadRequest("The selected budget does not exist.");
            var otherExpenses = targetBudget.Expenses.Where(item => item.Id != id).Sum(item => item.Amount);
            if (otherExpenses + dto.Amount > targetBudget.TotalAllocation) return BadRequest("This expense exceeds the remaining budget.");
            var targetCategory = targetBudget.Categories.FirstOrDefault(item => item.Name.Equals(dto.Category.Trim(), StringComparison.OrdinalIgnoreCase));
            var categorySpent = targetBudget.Expenses.Where(item => item.Id != id && item.Category.Equals(dto.Category.Trim(), StringComparison.OrdinalIgnoreCase)).Sum(item => item.Amount);
            if (targetCategory is not null && categorySpent + dto.Amount > targetCategory.AllocatedAmount) return BadRequest("This expense exceeds the remaining category allocation.");
            expense.BudgetId = dto.BudgetId; expense.Category = dto.Category.Trim(); expense.Description = dto.Description.Trim(); expense.Amount = dto.Amount; expense.ExpenseDate = DateTimeNormalization.ToUtc(dto.ExpenseDate);
            await _context.SaveChangesAsync(); return Ok(expense);
        }

        [HttpDelete("expenses/{id:int}")]
        [HttpDelete("~/api/expenses/{id:int}")]
        public async Task<IActionResult> DeleteExpense(int id) { var expense = await _context.Expenses.FindAsync(id); if (expense is null) return NotFound(); _context.Expenses.Remove(expense); await _context.SaveChangesAsync(); return NoContent(); }

        [HttpGet("{budgetId:int}/categories")]
        public async Task<IActionResult> GetCategories(int budgetId) => Ok(await _context.BudgetCategories.AsNoTracking().Where(category => category.BudgetId == budgetId).OrderBy(category => category.Name).ToListAsync());

        [HttpPost("{budgetId:int}/categories")]
        public async Task<IActionResult> AddCategory(int budgetId, BudgetCategoryDto dto)
        {
            if (dto.AllocatedAmount <= 0 || string.IsNullOrWhiteSpace(dto.Name)) return BadRequest("Category name and allocation must be valid.");
            var budget = await _context.Budgets.Include(item => item.Categories).SingleOrDefaultAsync(item => item.Id == budgetId);
            if (budget is null) return NotFound();
            if (budget.Categories.Any(category => category.Name.Equals(dto.Name.Trim(), StringComparison.OrdinalIgnoreCase))) return Conflict("A category with this name already exists.");
            if (budget.Categories.Sum(category => category.AllocatedAmount) + dto.AllocatedAmount > budget.TotalAllocation) return BadRequest("Category allocations cannot exceed the total budget.");
            var category = new BudgetCategory { BudgetId = budgetId, Name = dto.Name.Trim(), AllocatedAmount = dto.AllocatedAmount };
            _context.BudgetCategories.Add(category);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetCategories), new { budgetId }, category);
        }

        [HttpPut("{budgetId:int}/categories/{categoryId:int}")]
        public async Task<IActionResult> UpdateCategory(int budgetId, int categoryId, BudgetCategoryDto dto)
        {
            if (dto.AllocatedAmount <= 0 || string.IsNullOrWhiteSpace(dto.Name)) return BadRequest("Category name and allocation must be valid.");
            var budget = await _context.Budgets.Include(item => item.Categories).SingleOrDefaultAsync(item => item.Id == budgetId);
            var category = budget?.Categories.SingleOrDefault(item => item.Id == categoryId);
            if (budget is null || category is null) return NotFound();
            if (budget.Categories.Any(item => item.Id != categoryId && item.Name.ToLower() == dto.Name.Trim().ToLower())) return Conflict("A category with this name already exists.");
            if (budget.Categories.Where(item => item.Id != categoryId).Sum(item => item.AllocatedAmount) + dto.AllocatedAmount > budget.TotalAllocation) return BadRequest("Category allocations cannot exceed the total budget.");
            category.Name = dto.Name.Trim();
            category.AllocatedAmount = dto.AllocatedAmount;
            await _context.SaveChangesAsync();
            return Ok(category);
        }

        [HttpDelete("{budgetId:int}/categories/{categoryId:int}")]
        public async Task<IActionResult> DeleteCategory(int budgetId, int categoryId)
        {
            var category = await _context.BudgetCategories.SingleOrDefaultAsync(item => item.Id == categoryId && item.BudgetId == budgetId);
            if (category is null) return NotFound();
            _context.BudgetCategories.Remove(category);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}