using Microsoft.EntityFrameworkCore;
using TravelWise.API.Data;
using TravelWise.API.DTOs;
using TravelWise.API.Models;
using TravelWise.API.Utilities;

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
            var startTime = DateTimeNormalization.ToUtc(dto.StartTime);
            var endTime = DateTimeNormalization.ToUtc(dto.EndTime);

            // Enforce BR-ACT-01: Backend Validation for No Overlap
            var hasOverlap = await _context.Activities
                .AnyAsync(a => a.TripId == dto.TripId &&
                               a.StartTime < endTime &&
                               startTime < a.EndTime);

            if (hasOverlap)
                throw new InvalidOperationException("Activity times overlap with an existing schedule (BR-ACT-01).");

            var activity = new Activity
            {
                TripId = dto.TripId,
                Title = dto.Title,
                Description = dto.Description,
                StartTime = startTime,
                EndTime = endTime,
                Location = dto.Location,
                InterestType = dto.InterestType
            };

            _context.Activities.Add(activity);
            await _context.SaveChangesAsync();
            return activity;
        }
    }
}