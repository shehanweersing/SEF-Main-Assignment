using Microsoft.EntityFrameworkCore;
using TravelWise.API.Models;

namespace TravelWise.API.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        // Database tables
        public DbSet<User> Users { get; set; }
        public DbSet<Trip> Trips { get; set; }
    
        public DbSet<Budget> Budgets { get; set; }
        public DbSet<Expense> Expenses { get; set; }
        public DbSet<Activity> Activities { get; set; }
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Ensure emails are unique
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();
        }
    }
}