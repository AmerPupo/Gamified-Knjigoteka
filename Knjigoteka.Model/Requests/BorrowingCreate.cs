using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Requests
{
    public class BorrowingCreate
    {
        public int BookId { get; set; }
        public int UserId { get; set; }
        public int BranchId { get; set; }
        public int? ReservationId { get; set; }
    }

}
