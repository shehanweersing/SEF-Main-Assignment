using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TravelWise.API.Data;
using TravelWise.API.DTOs;
using TravelWise.API.Services;
using TravelWise.API.Utilities;

namespace TravelWise.API.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class ReadinessController : ControllerBase
    {
        private readonly ReadinessService _readinessService;
        private readonly ApplicationDbContext _context;

        public ReadinessController(ReadinessService readinessService, ApplicationDbContext context)
        {
            _readinessService = readinessService;
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetDocuments([FromQuery] int? tripId) => Ok(await _context.TravelDocuments.Where(d => !tripId.HasValue || d.TripId == tripId).OrderBy(d => d.ExpiryDate).ToListAsync());

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetDocument(int id) => await _context.TravelDocuments.FindAsync(id) is { } document ? Ok(document) : NotFound();

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

        [HttpPut("{id:int}")]
        public async Task<IActionResult> UpdateDocument(int id, [FromBody] CreateDocumentDto dto)
        {
            var document = await _context.TravelDocuments.FindAsync(id);
            if (document is null) return NotFound();
            var expiryDate = DateTimeNormalization.ToUtc(dto.ExpiryDate);
            if (expiryDate.Date <= DateTime.UtcNow.Date) return BadRequest("Document is already expired and cannot be used for travel (BR-READY-01).");
            document.TripId = dto.TripId; document.DocumentType = dto.DocumentType; document.DocumentNumber = dto.DocumentNumber; document.ExpiryDate = expiryDate;
            await _context.SaveChangesAsync();
            return Ok(document);
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteDocument(int id) { var document = await _context.TravelDocuments.FindAsync(id); if (document is null) return NotFound(); _context.TravelDocuments.Remove(document); await _context.SaveChangesAsync(); return NoContent(); }
    }
}