namespace TravelWise.API.DTOs
{
    public class CreateDocumentDto
    {
        public int TripId { get; set; }
        public string DocumentType { get; set; } = string.Empty;
        public string DocumentNumber { get; set; } = string.Empty;
        public DateTime ExpiryDate { get; set; }
    }
}