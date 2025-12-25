using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Requests
{
    public class SaleInsert
    {
        public int EmployeeId { get; set; }
        public List<SaleItemInsert> Items { get; set; } = new();
        public bool Sandbox { get; set; } = false;

        public int? BranchId { get; set; }
    }
}
