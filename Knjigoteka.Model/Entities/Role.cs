using System.ComponentModel.DataAnnotations;

namespace Knjigoteka.Model.Entities
{
    public class Role
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public string Name { get; set; } = null!; // Admin, Employee, User

        public ICollection<User> Users { get; set; } = new List<User>();
    }
}
