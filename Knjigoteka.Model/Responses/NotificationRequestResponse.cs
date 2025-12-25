using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Responses
{
    public class NotificationRequestResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int BookId { get; set; }
        public string BookTitle { get; set; }
        public int BranchId { get; set; }
        public string BranchName { get; set; } = null!;
        public DateTime RequestedAt { get; set; }
    }

}
