using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace TravelWise.API.Models;

public class BudgetCategory
{
    [Key]
    public int Id { get; set; }
    [Required]
    public int BudgetId { get; set; }
    [ForeignKey(nameof(BudgetId))]
    [JsonIgnore]
    public Budget? Budget { get; set; }
    [Required, MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    [Column(TypeName = "decimal(18,2)")]
    public decimal AllocatedAmount { get; set; }
}
