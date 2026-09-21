using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TravelWise.API.Models
{
    public class Activity
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int TripId { get; set; }
        
        [ForeignKey("TripId")]
        public Trip? Trip { get; set; }

        [Required]
        [MaxLength(150)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(500)]
        public string? Description { get; set; }

        [Required]
        public DateTime StartTime { get; set; }

        [Required]
        public DateTime EndTime { get; set; }

        [Required]
        [MaxLength(100)]
        public string Location { get; set; } = string.Empty;
        
        // E.g., "Nature", "Adventure", "Culture"
        [MaxLength(50)]
        public string? InterestType { get; set; } 
    }
}