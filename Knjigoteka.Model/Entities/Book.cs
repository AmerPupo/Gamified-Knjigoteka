using Knjigoteka.Model.Helpers;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Knjigoteka.Model.Entities
{
    public class Book
    {
        [Key]
        public int Id { get; set; }
        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = null!;
        [Required]
        [MaxLength(150)]
        public string Author { get; set; } = null!;
        [Required]
        public int GenreId { get; set; }
        [Required]
        public int LanguageId { get; set; }
        [Required]
        [RegularExpression(@"^(?=(?:[^0-9]*[0-9]){10}(?:(?:[^0-9]*[0-9]){3})?$)[\d-]+$", ErrorMessage = "Invalid ISBN format")]
        public string ISBN { get; set; } = null!;
        [CurrentYearRangeAttribute(0)]
        public int Year { get; set; }
        [Range(0, int.MaxValue)]
        public int CentralStock { get; set; }
        [NotMapped]
        public int CalculatedTotalQuantity =>
            (BookBranches?.Sum(bb => bb.QuantityForBorrow + bb.QuantityForSale) ?? 0) + CentralStock;
        [Required]
        [MaxLength(1000)]
        public string ShortDescription { get; set; } = null!;
        [Precision(18, 2)]
        [Range(0.01, 10000.00)]
        public decimal Price { get; set; }
        public byte[]? BookImage { get; set; } = null!;
        public string? BookImageContentType { get; set; }
        public bool IsSandbox { get; set; } = false;
        [ForeignKey(nameof(GenreId))]
        public Genre Genre { get; set; } = null!;
        [ForeignKey(nameof(LanguageId))]
        public Language Language { get; set; } = null!;
        public ICollection<BookBranch> BookBranches { get; set; } = new List<BookBranch>();
        public ICollection<Review> Reviews { get; set; } = new List<Review>();

    }
}
