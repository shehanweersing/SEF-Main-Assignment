using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TravelWise.API.Models
{
    public class Vote
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int ActivityId { get; set; }

        [ForeignKey("ActivityId")]
        public Activity? Activity { get; set; }

        [Required]
        public int UserId { get; set; }

        [ForeignKey("UserId")]
        public User? User { get; set; }

        [Required]
        [MaxLength(50)]
        public string VoteType { get; set; } = "Upvote"; // "Upvote", "Downvote"

        [MaxLength(500)]
        public string? Comment { get; set; }

        [Required]
        public DateTime VotedAt { get; set; } = DateTime.UtcNow;
    }
}
