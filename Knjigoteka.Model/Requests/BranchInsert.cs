using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Requests
{
    public class BranchInsert
    {
        public string Name { get; set; } = null!;
        public int CityId { get; set; }
        public string Address { get; set; } = null!;
        public string PhoneNumber { get; set; } = null!;
        public TimeOnly OpeningTime { get; set; } = TimeOnly.MinValue!;
        public TimeOnly ClosingTime { get; set; } = TimeOnly.MinValue!;

    }
}
