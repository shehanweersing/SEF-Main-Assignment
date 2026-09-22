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
        public async Task<IActionResult> AddBudget([FromBody] CreateBudgetDto dto) { if (dto.TotalAllocation <= 0) return BadRequest("Total allocation must be greater than zero."); var budget = new Budget { TripId = dto.TripId, TotalAllocation = dto.TotalAllocation, Currency = dto.Currency }; _context.Budgets.Add(budget); await _context.SaveChangesAsync(); return CreatedAtAction(nameof(GetBudget), new { id = budget.Id }, budget); }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> UpdateBudget(int id, [FromBody] CreateBudgetDto dto) { var budget = await _context.Budgets.FindAsync(id); if (budget is null) return NotFound(); if (dto.TotalAllocation <= 0) return BadRequest("Total allocation must be greater than zero."); budget.TripId = dto.TripId; budget.TotalAllocation = dto.TotalAllocation; budget.Currency = dto.Currency; await _context.SaveChangesAsync(); return Ok(budget); }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteBudget(int id) { var budget = await _context.Budgets.FindAsync(id); if (budget is null) return NotFound(); _context.Budgets.Remove(budget); await _context.SaveChangesAsync(); return NoContent(); }

        [HttpGet("expenses")]
        public async Task<IActionResult> GetExpenses([FromQuery] int? budgetId) => Ok(await _context.Expenses.Where(e => !budgetId.HasValue || e.BudgetId == budgetId).OrderByDescending(e => e.ExpenseDate).ToListAsync());

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

        [HttpPut("expenses/{id:int}")]
        public async Task<IActionResult> UpdateExpense(int id, [FromBody] CreateExpenseDto dto) { var expense = await _context.Expenses.FindAsync(id); if (expense is null) return NotFound(); if (dto.Amount <= 0) return BadRequest("Expense amount must be greater than zero."); expense.BudgetId = dto.BudgetId; expense.Category = dto.Category; expense.Description = dto.Description; expense.Amount = dto.Amount; expense.ExpenseDate = DateTimeNormalization.ToUtc(dto.ExpenseDate); await _context.SaveChangesAsync(); return Ok(expense); }

        [HttpDelete("expenses/{id:int}")]
        public async Task<IActionResult> DeleteExpense(int id) { var expense = await _context.Expenses.FindAsync(id); if (expense is null) return NotFound(); _context.Expenses.Remove(expense); await _context.SaveChangesAsync(); return NoContent(); }
    }
}