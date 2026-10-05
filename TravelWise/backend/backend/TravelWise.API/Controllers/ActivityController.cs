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
        public async Task<IActionResult> GetActivities([FromQuery] int? tripId, [FromQuery] string? search, [FromQuery] string? category, [FromQuery] int page = 1, [FromQuery] int pageSize = 25)
        {
            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 100);
            var query = _context.Activities.AsNoTracking().Where(a => !tripId.HasValue || a.TripId == tripId);
            if (!string.IsNullOrWhiteSpace(search)) query = query.Where(a => a.Title.Contains(search) || (a.Location != null && a.Location.Contains(search)));
            if (!string.IsNullOrWhiteSpace(category)) query = query.Where(a => a.Category == category || a.InterestType == category);
            var total = await query.CountAsync();
            var items = await query.OrderBy(a => a.StartTime).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
            return Ok(new { items, total, page, pageSize });
        }

        [HttpGet("~/api/activities/search")]
        public Task<IActionResult> SearchActivities([FromQuery] string? search, [FromQuery] string? category, [FromQuery] int page = 1, [FromQuery] int pageSize = 25) =>
            GetActivities(null, search, category, page, pageSize);

        [HttpGet("~/api/trips/{tripId:int}/schedule")]
        public Task<IActionResult> GetSchedule(int tripId) => GetActivities(tripId, null, null, 1, 100);

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetActivity(int id) => await _context.Activities.FindAsync(id) is { } activity ? Ok(activity) : NotFound();

        [HttpPost]
        public async Task<IActionResult> AddActivity([FromBody] CreateActivityDto dto)
        {
            var trip = await _context.Trips.FindAsync(dto.TripId);
            if (trip is null) return BadRequest("The selected trip does not exist.");
            if (dto.Cost < 0) return BadRequest("Activity cost cannot be negative.");

            var startTime = DateTimeNormalization.ToUtc(dto.StartTime);
            var endTime = DateTimeNormalization.ToUtc(dto.EndTime);
            if (startTime >= endTime) return BadRequest("Activity start time must be before its end time.");
            if (startTime < trip.StartDate || endTime > trip.EndDate) return BadRequest($"Activity must be scheduled between {trip.StartDate:u} and {trip.EndDate:u}.");
            if (string.IsNullOrWhiteSpace(dto.Location)) return BadRequest("Activity location is required.");
            var budget = await _context.Budgets.Include(item => item.Expenses).Include(item => item.Trip).SingleOrDefaultAsync(item => item.TripId == dto.TripId);
            if (budget is not null)
            {
                var committedActivityCost = await _context.Activities.Where(item => item.TripId == dto.TripId).SumAsync(item => item.Cost);
                var spent = budget.Expenses.Sum(item => item.Amount);
                if (spent + committedActivityCost + dto.Cost > budget.TotalAllocation) return BadRequest("Activity cost exceeds the remaining trip budget (BR-ACT-03).");
            }

            try
            {
                var activity = await _activityService.AddActivityAsync(dto);
                return CreatedAtAction(nameof(GetActivity), new { id = activity.Id }, activity);
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(ex.Message);
            }
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> UpdateActivity(int id, [FromBody] CreateActivityDto dto)
        {
            var activity = await _context.Activities.FindAsync(id);
            if (activity is null) return NotFound();

            var trip = await _context.Trips.FindAsync(dto.TripId);
            if (trip is null) return BadRequest("The selected trip does not exist.");

            var startTime = DateTimeNormalization.ToUtc(dto.StartTime);
            var endTime = DateTimeNormalization.ToUtc(dto.EndTime);
            if (startTime >= endTime) return BadRequest("Activity start time must be before its end time.");
            if (startTime < trip.StartDate || endTime > trip.EndDate) return BadRequest($"Activity must be scheduled between {trip.StartDate:u} and {trip.EndDate:u}.");
            if (string.IsNullOrWhiteSpace(dto.Location)) return BadRequest("Activity location is required.");

            var overlap = await _context.Activities.AnyAsync(a => a.Id != id && a.TripId == dto.TripId && a.StartTime < endTime && startTime < a.EndTime);
            if (overlap) return Conflict("Activity times overlap with an existing schedule (BR-ACT-01).");
            if (dto.Cost < 0) return BadRequest("Activity cost cannot be negative.");
            var budget = await _context.Budgets.Include(item => item.Expenses).SingleOrDefaultAsync(item => item.TripId == dto.TripId);
            if (budget is not null)
            {
                var committedActivityCost = await _context.Activities.Where(item => item.TripId == dto.TripId && item.Id != id).SumAsync(item => item.Cost);
                if (budget.Expenses.Sum(item => item.Amount) + committedActivityCost + dto.Cost > budget.TotalAllocation) return BadRequest("Activity cost exceeds the remaining trip budget (BR-ACT-03).");
            }

            activity.TripId = dto.TripId;
            activity.Title = dto.Title;
            activity.Description = dto.Description;
            activity.StartTime = startTime;
            activity.EndTime = endTime;
            activity.Location = dto.Location;
            activity.InterestType = dto.InterestType;
            activity.Cost = dto.Cost;
            activity.Category = dto.Category;
            activity.InterestTags = dto.InterestTags;
            await _context.SaveChangesAsync();
            return Ok(activity);
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteActivity(int id)
        {
            var activity = await _context.Activities.FindAsync(id);
            if (activity is null) return NotFound();
            _context.Activities.Remove(activity);
            await _context.SaveChangesAsync();
            return NoContent();
        }

        [HttpPost("~/api/trips/{tripId:int}/schedule")]
        public Task<IActionResult> AddToSchedule(int tripId, [FromBody] CreateActivityDto dto)
        {
            dto.TripId = tripId;
            return AddActivity(dto);
        }

        [HttpDelete("~/api/schedule/{id:int}")]
        public Task<IActionResult> RemoveFromSchedule(int id) => DeleteActivity(id);

        [HttpPost("~/api/trips/{tripId:int}/check-conflicts")]
        public async Task<IActionResult> CheckConflicts(int tripId)
        {
            var activities = await _context.Activities.Where(a => a.TripId == tripId).OrderBy(a => a.StartTime).ToListAsync();
            var conflicts = activities.Zip(activities.Skip(1), (first, second) => new { first, second })
                .Where(pair => pair.first.EndTime > pair.second.StartTime)
                .Select(pair => new { firstActivityId = pair.first.Id, secondActivityId = pair.second.Id, message = "Activities overlap." });
            return Ok(new { tripId, hasConflicts = conflicts.Any(), conflicts });
        }

        [HttpPost("~/api/trips/{tripId:int}/optimize-itinerary")]
        public async Task<IActionResult> OptimizeItinerary(int tripId)
        {
            var activities = await _context.Activities.Where(a => a.TripId == tripId).OrderBy(a => a.StartTime).ToListAsync();
            var conflicts = activities.Zip(activities.Skip(1), (first, second) => new { first, second })
                .Where(pair => pair.first.EndTime > pair.second.StartTime).ToList();
            if (conflicts.Count > 0) return Conflict(new { message = "Resolve overlapping activities before optimizing the itinerary.", conflictCount = conflicts.Count });
            return Ok(new { tripId, generatedBy = "TravelWise optimizer", items = activities, totalCost = activities.Sum(a => a.Cost), balanced = true });
        }
    }
}
