using Microsoft.AspNetCore.Mvc;
using TravelWise.API.DTOs;
using TravelWise.API.Services;

namespace TravelWise.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ReadinessController : ControllerBase
    {
        private readonly ReadinessService _readinessService;

        public ReadinessController(ReadinessService readinessService)
        {
            _readinessService = readinessService;
        }

        [HttpPost]
        public async Task<IActionResult> AddDocument([FromBody] CreateDocumentDto dto)
        {
            try
            {
                var document = await _readinessService.AddDocumentAsync(dto);
                return CreatedAtAction(nameof(AddDocument), new { id = document.Id }, document);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ex.Message);
            }
        }
    }
}