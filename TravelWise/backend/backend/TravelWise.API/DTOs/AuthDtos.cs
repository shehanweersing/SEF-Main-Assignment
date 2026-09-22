using System.ComponentModel.DataAnnotations;

namespace TravelWise.API.DTOs
{
    public class RegisterDto
    {
        [Required(ErrorMessage = "Full name is required.")]
        public string FullName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Email is required.")]
        [EmailAddress(ErrorMessage = "Invalid email format.")]
        // This Regex specifically forces the email to end in common domains, blocking typos like .cm
        [RegularExpression(@"^[^@\s]+@[^@\s]+\.(com|net|org|edu|lk)$", ErrorMessage = "Email must end in a valid domain (e.g., .com, .lk).")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Password is required.")]
        [MinLength(6, ErrorMessage = "Password must be at least 6 characters long.")]
        public string Password { get; set; } = string.Empty;

        public string Role { get; set; } = "Traveller"; // Default role
    }

    public class LoginDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string Password { get; set; } = string.Empty;
    }
}