using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TravelWise.API.Models
{
    public class ConsensusRecord
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int TripId { get; set; }

        [ForeignKey("TripId")]
        public Trip? Trip { get; set; }

        [Required]
        public DateTime ResolvedAt { get; set; } = DateTime.UtcNow;

        [Required]
        public double FairnessScore { get; set; } // Percentage based calculation

        [Required]
        public string DecisionsJson { get; set; } = string.Empty; // Serialized string of consensus itinerary decisions
    }
}
