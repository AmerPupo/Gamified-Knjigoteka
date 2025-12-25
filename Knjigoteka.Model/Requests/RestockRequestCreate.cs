
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Requests
{
    public class RestockRequestCreate
    {
        public int BookId { get; set; }
        public int QuantityRequested { get; set; }
    }
}
