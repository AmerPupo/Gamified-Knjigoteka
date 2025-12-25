using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Responses
{
    public class OrderItemResponse
    {
        public int BookId { get; set; }
        public string Title { get; set; } = null!;
        public string? Author { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal LineTotal => UnitPrice * Quantity;
        public string? PhotoEndpoint { get; set; }
    }
}
