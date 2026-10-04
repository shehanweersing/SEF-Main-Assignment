using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TravelWise.API.Models
{
    public class MemberPreference
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int TripId { get; set; }

        [ForeignKey("TripId")]
        public Trip? Trip { get; set; }

        [Required]
        public int UserId { get; set; }

        [ForeignKey("UserId")]
        public User? User { get; set; }

        [Required]
        [MaxLength(100)]
        public string Category { get; set; } = string.Empty; // E.g., "Nature", "Adventure", "Culture", "Budget", "Relaxation"

        [Required]
        public double Weight { get; set; } = 1.0; // Scale 1 to 5

        [MaxLength(500)]
        public string? Notes { get; set; }
    }
}
