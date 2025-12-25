using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.SearchObjects
{
    public class ReservationSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? BranchId { get; set; }
        public string? Status { get; set; }
        public bool ActiveOnly { get; set; } = false;
        public string? UserName {  get; set; }
        public bool Sandbox { get; set; } = false;

    }

}
