using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Responses
{
    public class BranchReportResponse
    {
        public int BranchId { get; set; }
        public string BranchName { get; set; }
        public int TotalSold { get; set; }
        public int TotalBorrowed { get; set; }
        public List<BranchReportEntry> Entries { get; set; } = new();
    }
}
