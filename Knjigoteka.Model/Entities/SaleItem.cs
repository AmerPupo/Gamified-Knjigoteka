using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Entities
{
    public class SaleItem
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public int SaleId { get; set; }
        [Required]
        public int BookId { get; set; }
        [Required]
        [Range(0, int.MaxValue, ErrorMessage = "Quantity must be greater than 0")]
        public int Quantity { get; set; }
        [Required]
        [Precision(18, 2)]
        public decimal UnitPrice { get; set; }
        [ForeignKey(nameof(BookId))]
        public Book Book { get; set; } = null!;
        [ForeignKey(nameof(SaleId))]
        public Sale Sale { get; set; } = null!;
    }

}
