using System.ComponentModel.DataAnnotations;

namespace Knjigoteka.Model.Entities
{
    public class Language
    {
        [Key]
        public int Id { get; set; }
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = null!;

        public ICollection<Book> Books { get; set; } = new List<Book>();
    }
}
