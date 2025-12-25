using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Responses
{
    public class CartResponse
    {
        public List<CartItemResponse> Items { get; set; } = new();
        public decimal Total => Items.Sum(i => i.LineTotal);
    }

}
