using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Requests
{
    public class SaleItemInsert
    {
        public int BookId { get; set; }
        public int Quantity { get; set; }
    }
}
