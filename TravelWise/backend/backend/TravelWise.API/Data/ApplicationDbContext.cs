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
        public DbSet<RiskAssessment> RiskAssessments { get; set; }
        public DbSet<TravelDocument> TravelDocuments { get; set; }
        public DbSet<TripMember> TripMembers { get; set; }
        public DbSet<Invitation> Invitations { get; set; }
        public DbSet<MemberPreference> MemberPreferences { get; set; }
        public DbSet<Vote> Votes { get; set; }
        public DbSet<ConsensusRecord> ConsensusRecords { get; set; }
        public DbSet<BudgetCategory> BudgetCategories { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Ensure emails are unique
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();

            modelBuilder.Entity<TripMember>()
                .HasIndex(m => new { m.TripId, m.UserId })
                .IsUnique();

            modelBuilder.Entity<MemberPreference>()
                .HasIndex(p => new { p.TripId, p.UserId, p.Category })
                .IsUnique();

            modelBuilder.Entity<Vote>()
                .HasIndex(v => new { v.ActivityId, v.UserId })
                .IsUnique();

            modelBuilder.Entity<BudgetCategory>()
                .HasIndex(category => new { category.BudgetId, category.Name })
                .IsUnique();
        }
    }
}