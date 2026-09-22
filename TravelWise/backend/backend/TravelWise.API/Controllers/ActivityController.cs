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
    public class ActivityController : ControllerBase
    {
        private readonly ActivityService _activityService;
        private readonly ApplicationDbContext _context;

        public ActivityController(ActivityService activityService, ApplicationDbContext context)
        {
            _activityService = activityService;
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetActivities([FromQuery] int? tripId) => Ok(await _context.Activities.Where(a => !tripId.HasValue || a.TripId == tripId).OrderBy(a => a.StartTime).ToListAsync());

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetActivity(int id) => await _context.Activities.FindAsync(id) is { } activity ? Ok(activity) : NotFound();

        [HttpPost]
        public async Task<IActionResult> AddActivity([FromBody] CreateActivityDto dto)
        {
            try
            {
                if (!await _context.Trips.AnyAsync(t => t.Id == dto.TripId)) return BadRequest("The selected trip does not exist.");
                var activity = await _activityService.AddActivityAsync(dto);
                return CreatedAtAction(nameof(AddActivity), new { id = activity.Id }, activity);
            }
            catch (InvalidOperationException ex)
            {
                // Returns a 409 Conflict if BR-ACT-01 fails
                return Conflict(ex.Message);
            }
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> UpdateActivity(int id, [FromBody] CreateActivityDto dto)
        {
            var activity = await _context.Activities.FindAsync(id);
            if (activity is null) return NotFound();
            var startTime = DateTimeNormalization.ToUtc(dto.StartTime);
            var endTime = DateTimeNormalization.ToUtc(dto.EndTime);
            var overlap = await _context.Activities.AnyAsync(a => a.Id != id && a.TripId == dto.TripId && a.StartTime < endTime && startTime < a.EndTime);
            if (overlap) return Conflict("Activity times overlap with an existing schedule (BR-ACT-01).");
            activity.TripId = dto.TripId; activity.Title = dto.Title; activity.Description = dto.Description; activity.StartTime = startTime; activity.EndTime = endTime; activity.Location = dto.Location; activity.InterestType = dto.InterestType;
            await _context.SaveChangesAsync();
            return Ok(activity);
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteActivity(int id) { var activity = await _context.Activities.FindAsync(id); if (activity is null) return NotFound(); _context.Activities.Remove(activity); await _context.SaveChangesAsync(); return NoContent(); }
    }
}