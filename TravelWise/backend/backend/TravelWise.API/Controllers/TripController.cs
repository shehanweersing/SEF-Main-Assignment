using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TravelWise.API.Data;
using TravelWise.API.Models;
using TravelWise.API.Utilities;

namespace TravelWise.API.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class TripController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        public TripController(ApplicationDbContext context) => _context = context;

        [HttpGet]
        public async Task<IActionResult> GetTrips([FromQuery] int? userId, [FromQuery] string? search)
        {
            var query = _context.Trips.AsQueryable();
            if (userId.HasValue) query = query.Where(t => t.UserId == userId);
            if (!string.IsNullOrWhiteSpace(search)) query = query.Where(t => EF.Functions.ILike(t.Destination, $"%{search}%") || (t.TravelObjective != null && EF.Functions.ILike(t.TravelObjective, $"%{search}%")));
            return Ok(await query.OrderByDescending(t => t.StartDate).ToListAsync());
        }

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetTrip(int id) => await _context.Trips.FindAsync(id) is { } trip ? Ok(trip) : NotFound();

        [HttpPost]
        public async Task<IActionResult> CreateTrip([FromBody] Trip trip) { trip.Id = 0; trip.StartDate = DateTimeNormalization.ToUtc(trip.StartDate); trip.EndDate = DateTimeNormalization.ToUtc(trip.EndDate); trip.CreatedAt = DateTime.UtcNow; trip.UpdatedAt = DateTime.UtcNow; if (string.IsNullOrWhiteSpace(trip.Status)) trip.Status = "Created"; _context.Trips.Add(trip); await _context.SaveChangesAsync(); return CreatedAtAction(nameof(GetTrip), new { id = trip.Id }, trip); }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> UpdateTrip(int id, [FromBody] Trip input) { var trip = await _context.Trips.FindAsync(id); if (trip is null) return NotFound(); trip.UserId = input.UserId; trip.Destination = input.Destination; trip.StartDate = DateTimeNormalization.ToUtc(input.StartDate); trip.EndDate = DateTimeNormalization.ToUtc(input.EndDate); trip.TravelObjective = input.TravelObjective; trip.Status = input.Status; trip.UpdatedAt = DateTime.UtcNow; await _context.SaveChangesAsync(); return Ok(trip); }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteTrip(int id) { var trip = await _context.Trips.FindAsync(id); if (trip is null) return NotFound(); _context.Trips.Remove(trip); await _context.SaveChangesAsync(); return NoContent(); }
    }
}