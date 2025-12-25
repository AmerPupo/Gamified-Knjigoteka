using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Knjigoteka.Model.Entities
{
    public class Branch
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public string Name { get; set; } = null!;
        [Required]
        public int CityId { get; set; }
        [Required]
        public string Address { get; set; } = null!;
        [Required]
        [Phone(ErrorMessage = "Invalid phone number format")]
        public string PhoneNumber { get; set; } = null!;
        [Required]
        public TimeOnly OpeningTime { get; set; }
        [Required]
        public TimeOnly ClosingTime { get; set; }
        public bool IsSandbox { get; set; } = false;

        [ForeignKey(nameof(CityId))]
        public City City { get; set; } = null!;
        public ICollection<BookBranch> BookBranches { get; set; } = new List<BookBranch>();
        public ICollection<Employee> Employees { get; set; } = new List<Employee>();
        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        public ICollection<RestockRequest> RestockRequests { get; set; } = new List<RestockRequest>();

    }
}