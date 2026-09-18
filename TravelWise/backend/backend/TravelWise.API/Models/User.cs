using System.ComponentModel.DataAnnotations;

namespace TravelWise.API.Models
{
    public class User
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string FullName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [MaxLength(150)]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string PasswordHash { get; set; } = string.Empty;

        // Roles: "Admin", "Staff" (React web app), or "Traveller" (Flutter mobile app)[cite: 1, 3]
        [Required]
        public string Role { get; set; } = "Traveller";

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation property for related trips
        public ICollection<Trip> Trips { get; set; } = new List<Trip>();
    }
}