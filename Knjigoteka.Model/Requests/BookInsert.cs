using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Requests
{
    public class BookInsert
    {
        public string Title { get; set; } = null!;
        public string Author { get; set; } = null!;
        public int GenreId { get; set; }
        public int LanguageId { get; set; }
        public string ISBN { get; set; } = null!;
        public int Year { get; set; }
        public int CentralStock { get; set; }
        public string ShortDescription { get; set; } = null!;
        public decimal Price { get; set; }
        public byte[] BookImage { get; set; } = null!;
    }
}
