using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Knjigoteka.Model.Entities
{
    public class CartItem
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public int UserId { get; set; }
        [Required]
        public int BookId { get; set; }
        [Required]
        [Range(0, int.MaxValue, ErrorMessage ="Quantity must be greater than 0")]
        public int Quantity { get; set; }
        public DateTime AddedAt { get; set; } = DateTime.Now;

        [ForeignKey(nameof(UserId))]
        public User User { get; set; } = null!;
        [ForeignKey(nameof(BookId))]
        public Book Book { get; set; } = null!;
    }
}
