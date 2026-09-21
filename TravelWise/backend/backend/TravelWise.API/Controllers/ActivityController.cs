using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TravelWise.API.DTOs;
using TravelWise.API.Services;

namespace TravelWise.API.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class ActivityController : ControllerBase
    {
        private readonly ActivityService _activityService;

        public ActivityController(ActivityService activityService)
        {
            _activityService = activityService;
        }

        [HttpPost]
        public async Task<IActionResult> AddActivity([FromBody] CreateActivityDto dto)
        {
            try
            {
                var activity = await _activityService.AddActivityAsync(dto);
                return CreatedAtAction(nameof(AddActivity), new { id = activity.Id }, activity);
            }
            catch (InvalidOperationException ex)
            {
                // Returns a 409 Conflict if BR-ACT-01 fails
                return Conflict(ex.Message);
            }
        }
    }
}