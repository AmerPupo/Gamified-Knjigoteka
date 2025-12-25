using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Requests
{
    public class BranchReportRequest
    {
        public int BranchId { get; set; }
        public DateTime? From { get; set; }
        public DateTime? To { get; set; }
    }

}
