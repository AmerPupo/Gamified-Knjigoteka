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
    public class Sale
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public int EmployeeId { get; set; }
        [Required]
        public DateTime SaleDate { get; set; } = DateTime.Now;
        [Required]
        [Precision(18, 2)]
        public decimal TotalAmount { get; set; }
        public List<SaleItem> Items { get; set; } = new List<SaleItem>();
        public bool IsSandbox { get; set; } = false;

        [ForeignKey(nameof(EmployeeId))]
        public Employee Employee { get; set; } = null!;

    }

}
