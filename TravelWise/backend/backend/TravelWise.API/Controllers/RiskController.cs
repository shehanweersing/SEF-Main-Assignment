using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TravelWise.API.Data;
using TravelWise.API.DTOs;
using TravelWise.API.Services;

namespace TravelWise.API.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class RiskController : ControllerBase
    {
        private readonly RiskService _riskService;
        private readonly ApplicationDbContext _context;

        public RiskController(RiskService riskService, ApplicationDbContext context)
        {
            _riskService = riskService;
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetAssessments([FromQuery] int? tripId) => Ok(await _context.RiskAssessments.Where(r => !tripId.HasValue || r.TripId == tripId).OrderByDescending(r => r.AssessmentDate).ToListAsync());

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetAssessment(int id) => await _context.RiskAssessments.FindAsync(id) is { } assessment ? Ok(assessment) : NotFound();

        [HttpPost]
        public async Task<IActionResult> AddRiskAssessment([FromBody] CreateRiskAssessmentDto dto)
        {
            try
            {
                if (!await _context.Trips.AnyAsync(t => t.Id == dto.TripId)) return BadRequest("The selected trip does not exist.");
                var assessment = await _riskService.AddRiskAssessmentAsync(dto);
                return CreatedAtAction(nameof(AddRiskAssessment), new { id = assessment.Id }, assessment);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> UpdateAssessment(int id, [FromBody] CreateRiskAssessmentDto dto)
        {
            var assessment = await _context.RiskAssessments.FindAsync(id);
            if (assessment is null) return NotFound();
            if (!new[] { "Low", "Moderate", "High", "Critical" }.Contains(dto.SeverityLevel)) return BadRequest("Invalid severity level.");
            assessment.TripId = dto.TripId; assessment.Destination = dto.Destination; assessment.SeverityLevel = dto.SeverityLevel; assessment.AdvisoryMessage = dto.AdvisoryMessage;
            await _context.SaveChangesAsync();
            return Ok(assessment);
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteAssessment(int id) { var assessment = await _context.RiskAssessments.FindAsync(id); if (assessment is null) return NotFound(); _context.RiskAssessments.Remove(assessment); await _context.SaveChangesAsync(); return NoContent(); }
    }
}