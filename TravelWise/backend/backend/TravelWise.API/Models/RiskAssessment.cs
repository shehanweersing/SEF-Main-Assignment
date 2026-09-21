using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TravelWise.API.Models
{
    public class RiskAssessment
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int TripId { get; set; }
        
        [ForeignKey("TripId")]
        public Trip? Trip { get; set; }

        [Required]
        [MaxLength(200)]
        public string Destination { get; set; } = string.Empty;

        // Valid levels: "Low", "Moderate", "High", "Critical"
        [Required]
        [MaxLength(50)]
        public string SeverityLevel { get; set; } = string.Empty; 

        [Required]
        public string AdvisoryMessage { get; set; } = string.Empty;

        public DateTime AssessmentDate { get; set; } = DateTime.UtcNow;
    }
}