using Knjigoteka.Model.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Requests
{
    public class RestockRequestUpdate
    {
        public int QuantityRequested { get; set; }
    }
}
