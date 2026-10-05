using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace TravelWise.API.Models
{
    public class Expense
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int BudgetId { get; set; }

        [NotMapped]
        public int TripId => Budget?.TripId ?? 0;
        
        [ForeignKey("BudgetId")]
        [JsonIgnore]
        public Budget? Budget { get; set; }

        [Required]
        [MaxLength(100)]
        public string Category { get; set; } = string.Empty; // e.g., "Transport", "Food", "Accommodation"

        [Required]
        [MaxLength(200)]
        public string Description { get; set; } = string.Empty;

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        [Required]
        public DateTime ExpenseDate { get; set; }
    }
}