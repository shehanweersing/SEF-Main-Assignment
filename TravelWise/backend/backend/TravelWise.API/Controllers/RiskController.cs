using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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

        public RiskController(RiskService riskService)
        {
            _riskService = riskService;
        }

        [HttpPost]
        public async Task<IActionResult> AddRiskAssessment([FromBody] CreateRiskAssessmentDto dto)
        {
            try
            {
                var assessment = await _riskService.AddRiskAssessmentAsync(dto);
                return CreatedAtAction(nameof(AddRiskAssessment), new { id = assessment.Id }, assessment);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ex.Message);
            }
        }
    }
}