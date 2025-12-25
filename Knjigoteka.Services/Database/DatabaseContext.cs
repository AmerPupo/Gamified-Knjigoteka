using Knjigoteka.Model.Entities;
using Microsoft.EntityFrameworkCore;

namespace Knjigoteka.Services.Database
{
    public class DatabaseContext : DbContext
    {
        public DatabaseContext(DbContextOptions options) : base(options) { }

        public DbSet<Book> Books { get; set; } = null!;
        public DbSet<BookBranch> BookBranches { get; set; } = null!;
        public DbSet<Borrowing> Borrowings { get; set; } = null!;
        public DbSet<Branch> Branches { get; set; } = null!;
        public DbSet<CartItem> CartItems { get; set; } = null!;
        public DbSet<City> Cities { get; set; } = null!;
        public DbSet<Employee> Employees { get; set; } = null!;
        public DbSet<Genre> Genres { get; set; } = null!;
        public DbSet<Language> Languages { get; set; } = null!;
        public DbSet<NotificationRequest> NotificationRequests { get; set; } = null!;
        public DbSet<Order> Orders { get; set; } = null!;
        public DbSet<OrderItem> OrderItems { get; set; } = null!;
        public DbSet<Payment> Payments { get; set; } = null!;
        public DbSet<Penalty> Penalties { get; set; } = null!;
        public DbSet<Reservation> Reservations { get; set; } = null!;
        public DbSet<RestockRequest> RestockRequests { get; set; } = null!;
        public DbSet<Review> Reviews { get; set; } = null!;
        public DbSet<Role> Roles { get; set; } = null!;
        public DbSet<Sale> Sales { get; set; } = null!;
        public DbSet<SaleItem> SalesItems { get; set; } = null!;
        public DbSet<User> Users { get; set; } = null!;
        public DbSet<OnboardingProgress> OnboardingProgresses { get; set; } = null!;


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {

            modelBuilder.Entity<RestockRequest>(entity =>
            {
                entity.HasKey(rr => rr.Id);

                entity.HasOne(rr => rr.Book)
                      .WithMany()
                      .HasForeignKey(rr => rr.BookId)
                      .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(rr => rr.Branch)
                      .WithMany(br => br.RestockRequests)
                      .HasForeignKey(rr => rr.BranchId)
                      .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(rr => rr.Employee)
                      .WithMany()
                      .HasForeignKey(rr => rr.EmployeeId)
                      .OnDelete(DeleteBehavior.Restrict);

                entity.Property(rr => rr.QuantityRequested).IsRequired();
                entity.Property(rr => rr.Status).IsRequired();
            });

            modelBuilder.Entity<BookBranch>(entity =>
            {
                entity.HasKey(bb => new { bb.BookId, bb.BranchId });

                entity.HasOne(bb => bb.Book)
                      .WithMany(b => b.BookBranches)
                      .HasForeignKey(bb => bb.BookId)
                      .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(bb => bb.Branch)
                      .WithMany(br => br.BookBranches)
                      .HasForeignKey(bb => bb.BranchId)
                      .OnDelete(DeleteBehavior.Cascade);

                entity.Property(bb => bb.QuantityForBorrow).HasDefaultValue(0);
                entity.Property(bb => bb.QuantityForSale).HasDefaultValue(0);
            });
            modelBuilder.Entity<Reservation>()
            .HasIndex(r => new {
                r.BookId,
                r.BranchId,
                r.UserId,
                r.Status
            });
            modelBuilder.Entity<Book>()
                .HasQueryFilter(b => !b.IsSandbox);

            modelBuilder.Entity<BookBranch>()
                .HasQueryFilter(bb => !bb.IsSandbox);

            modelBuilder.Entity<Borrowing>()
                .HasQueryFilter(b => !b.IsSandbox);

            modelBuilder.Entity<Reservation>()
                .HasQueryFilter(r => !r.IsSandbox);

            modelBuilder.Entity<RestockRequest>()
                .HasQueryFilter(r => !r.IsSandbox);

            modelBuilder.Entity<Sale>()
                .HasQueryFilter(s => !s.IsSandbox);

            modelBuilder.Entity<Branch>()
                .HasQueryFilter(b => !b.IsSandbox);
            base.OnModelCreating(modelBuilder);

        }

    }
}
