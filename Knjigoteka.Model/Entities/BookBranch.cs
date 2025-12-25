using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Knjigoteka.Model.Entities
{
    public class BookBranch
    {
        [Required]
        public int BookId { get; set; }
        [Required]

        public int BranchId { get; set; }
        public bool SupportsBorrowing { get; set; }

        [Required]
        [Range(0, int.MaxValue, ErrorMessage = "Quantity for borrowing must be zero or more.")]
        public int QuantityForBorrow { get; set; }
        [Required]
        [Range(0, int.MaxValue, ErrorMessage = "Quantity for sale must be zero or more.")]
        public int QuantityForSale { get; set; }
        public bool IsSandbox { get; set; } = false;

        [ForeignKey(nameof(BookId))]
        public Book Book { get; set; } = null!;
        [ForeignKey(nameof(BranchId))]
        public Branch Branch { get; set; } = null!;
    }
}
