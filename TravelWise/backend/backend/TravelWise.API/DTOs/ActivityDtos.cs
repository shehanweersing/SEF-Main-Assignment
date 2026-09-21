namespace TravelWise.API.DTOs
{
    public class CreateActivityDto
    {
        public int TripId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string Location { get; set; } = string.Empty;
        public string? InterestType { get; set; }
    }
}