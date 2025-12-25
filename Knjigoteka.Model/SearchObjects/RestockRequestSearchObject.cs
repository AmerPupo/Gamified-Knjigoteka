using Knjigoteka.Model.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.SearchObjects
{
    public class RestockRequestSearchObject : BaseSearchObject
    {
        public int? BookId { get; set; }
        public int? BranchId { get; set; }
        public int? EmployeeId { get; set; }
        public RestockRequestStatus? Status { get; set; }
    }
}
