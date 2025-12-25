using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace Knjigoteka.Model.Entities
{
    public class RestockRequest
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public int BookId { get; set; }
        [Required]
        public int BranchId { get; set; }
        [Required]
        public int EmployeeId { get; set; }
        [Required]
        public DateTime RequestDate { get; set; } = DateTime.Now;

        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be greater than 0.")]
        public int QuantityRequested { get; set; }
        [Required]
        public RestockRequestStatus Status { get; set; } = RestockRequestStatus.Pending;
        public bool IsSandbox { get; set; } = false;

        [ForeignKey(nameof(BookId))]
        public Book Book { get; set; } = null!;
        [ForeignKey(nameof(BranchId))]
        public Branch Branch { get; set; } = null!;
        [ForeignKey(nameof(EmployeeId))]
        public Employee Employee { get; set; } = null!;
    }
    public enum RestockRequestStatus
    {
        Pending,
        Approved,
        Recieved,
        Rejected
    }

}
