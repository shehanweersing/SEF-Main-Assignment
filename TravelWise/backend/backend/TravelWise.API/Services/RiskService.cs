using TravelWise.API.Data;
using TravelWise.API.DTOs;
using TravelWise.API.Models;

namespace TravelWise.API.Services
{
    public class RiskService
    {
        private readonly ApplicationDbContext _context;
        private readonly string[] _validSeverities = { "Low", "Moderate", "High", "Critical" };

        public RiskService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<RiskAssessment> AddRiskAssessmentAsync(CreateRiskAssessmentDto dto)
        {
            // Enforce BR-RISK-01: Valid Severity Levels Only[cite: 3]
            if (!_validSeverities.Contains(dto.SeverityLevel))
                throw new ArgumentException($"Invalid severity level. Must be one of: {string.Join(", ", _validSeverities)} (BR-RISK-01)");

            var assessment = new RiskAssessment
            {
                TripId = dto.TripId,
                Destination = dto.Destination,
                SeverityLevel = dto.SeverityLevel,
                AdvisoryMessage = dto.AdvisoryMessage
            };

            _context.RiskAssessments.Add(assessment);
            await _context.SaveChangesAsync();
            return assessment;
        }
    }
}