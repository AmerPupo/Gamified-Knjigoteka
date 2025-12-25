using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Responses
{
    public class ReservationResponse
    {
        public int Id { get; set; }
        public int UserId {  get; set; }
        public string UserName { get; set; }
        public int BookId { get; set; }
        public string BookTitle { get; set; } = string.Empty;
        public int BranchId { get; set; }
        public string BranchName { get; set; } = string.Empty;
        public DateTime ReservedAt { get; set; }
        public DateTime? ClaimedAt { get; set; }
        public DateTime? ReturnedAt { get; set; }
        public DateTime? ExpiredAt { get; set; }
        public string Status { get; set; } = string.Empty;
    }

}
