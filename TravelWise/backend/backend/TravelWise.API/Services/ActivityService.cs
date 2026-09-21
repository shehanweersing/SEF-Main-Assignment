using Microsoft.EntityFrameworkCore;
using TravelWise.API.Data;
using TravelWise.API.DTOs;
using TravelWise.API.Models;

namespace TravelWise.API.Services
{
    public class ActivityService
    {
        private readonly ApplicationDbContext _context;

        public ActivityService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<Activity> AddActivityAsync(CreateActivityDto dto)
        {
            // Enforce BR-ACT-01: Backend Validation for No Overlap
            var hasOverlap = await _context.Activities
                .AnyAsync(a => a.TripId == dto.TripId &&
                               a.StartTime < dto.EndTime &&
                               dto.StartTime < a.EndTime);

            if (hasOverlap)
                throw new InvalidOperationException("Activity times overlap with an existing schedule (BR-ACT-01).");

            var activity = new Activity
            {
                TripId = dto.TripId,
                Title = dto.Title,
                Description = dto.Description,
                StartTime = dto.StartTime,
                EndTime = dto.EndTime,
                Location = dto.Location,
                InterestType = dto.InterestType
            };

            _context.Activities.Add(activity);
            await _context.SaveChangesAsync();
            return activity;
        }
    }
}