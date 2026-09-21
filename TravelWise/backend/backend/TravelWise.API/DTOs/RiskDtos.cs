namespace TravelWise.API.DTOs
{
    public class CreateRiskAssessmentDto
    {
        public int TripId { get; set; }
        public string Destination { get; set; } = string.Empty;
        public string SeverityLevel { get; set; } = string.Empty;
        public string AdvisoryMessage { get; set; } = string.Empty;
    }
}