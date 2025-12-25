using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Responses
{
    public class BranchResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
        public int CityId { get; set; }
        public string CityName { get; set; } = null!;
        public string Address { get; set; } = null!;
        public string PhoneNumber { get; set; } = null!;
        public TimeOnly OpeningTime { get; set; } = TimeOnly.MinValue!;
        public TimeOnly ClosingTime { get; set; } = TimeOnly.MinValue!;

    }
}
