using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TravelWise.API.Models
{
    public class Budget
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int TripId { get; set; }
        
        [ForeignKey("TripId")]
        public Trip? Trip { get; set; }

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalAllocation { get; set; }

        [Required]
        [MaxLength(3)]
        public string Currency { get; set; } = "LKR"; // Defaulting to Sri Lankan Rupees for your context

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation property for individual expenses
        public ICollection<Expense> Expenses { get; set; } = new List<Expense>();
    }
}