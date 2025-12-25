using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Responses
{
    public class BranchReportEntry
    {
        public DateTime Date { get; set; }
        public int Sold { get; set; }
        public int Borrowed { get; set; }
    }
}
