using Microsoft.AspNetCore.Mvc;
using TravelWise.API.DTOs;
using TravelWise.API.Services;

namespace TravelWise.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BudgetController : ControllerBase
    {
        private readonly BudgetService _budgetService;

        public BudgetController(BudgetService budgetService)
        {
            _budgetService = budgetService;
        }

        [HttpPost("expenses")]
        public async Task<IActionResult> AddExpense([FromBody] CreateExpenseDto dto)
        {
            try
            {
                var expense = await _budgetService.AddExpenseAsync(dto);
                return CreatedAtAction(nameof(AddExpense), new { id = expense.Id }, expense);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ex.Message);
            }
        }
    }
}