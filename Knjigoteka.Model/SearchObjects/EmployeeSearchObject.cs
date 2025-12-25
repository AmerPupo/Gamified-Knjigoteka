using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.SearchObjects
{
    public class EmployeeSearchObject : BaseSearchObject
    {
        public string? NameFTS { get; set; }
        public int? BranchId { get; set; }
        public DateTime? HiredAfter { get; set; }
        public DateTime? HiredBefore { get; set; }
    }

}
