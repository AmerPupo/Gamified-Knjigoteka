using Microsoft.Identity.Client;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Knjigoteka.Model.Entities
{
    public class Borrowing
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public int BookId { get; set; }
        [Required]
        public int UserId { get; set; }
        [Required]
        public int BranchId { get; set; }
        public int? ReservationId { get; set; }
        [Required]
        public DateTime BorrowedAt { get; set; } = DateTime.Now;
        [Required]
        public DateTime DueDate { get; set; } = DateTime.Now.AddDays(30);
        public DateTime? ReturnedAt { get; set; }
        public bool IsLate => ReturnedAt.HasValue && ReturnedAt.Value > DueDate;
        public bool IsSandbox { get; set; } = false;

        [ForeignKey(nameof(BookId))]
        public Book Book { get; set; } = null!;
        [ForeignKey(nameof(UserId))]
        public User User { get; set; } = null!;
        [ForeignKey(nameof(BranchId))]
        public Branch Branch { get; set; } = null!;
        [ForeignKey(nameof(ReservationId))]
        public Reservation? Reservation { get; set; }
    }
}
