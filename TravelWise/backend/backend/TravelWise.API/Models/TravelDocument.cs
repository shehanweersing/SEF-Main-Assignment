using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TravelWise.API.Models
{
    public class TravelDocument
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int TripId { get; set; }
        
        [ForeignKey("TripId")]
        public Trip? Trip { get; set; }

        [Required]
        [MaxLength(100)]
        public string DocumentType { get; set; } = string.Empty; // e.g., "Passport", "Visa"

        [Required]
        [MaxLength(150)]
        public string DocumentNumber { get; set; } = string.Empty;

        [Required]
        public DateTime ExpiryDate { get; set; }

        public bool IsVerified { get; set; } = false;
    }
}