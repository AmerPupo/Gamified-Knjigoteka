using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Requests
{
    public class EmployeeInsert
    {
        public int UserId { get; set; }
        public int BranchId { get; set; }
    }
}
