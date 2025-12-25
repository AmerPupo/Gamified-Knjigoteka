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
    public class Payment
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public int OrderId { get; set; }
        [ForeignKey(nameof(OrderId))]
        public Order Order { get; set; } = null!;

        public string Method { get; set; } = null!; // e.g. Stripe, Cash
        [Required]
        [Precision(18, 2)]
        public decimal Amount { get; set; }
        public DateTime? PaidAt { get; set; } = DateTime.Now;
        public string Status { get; set; } = "Pending"; // Optional: Paid, Failed
    }
}
