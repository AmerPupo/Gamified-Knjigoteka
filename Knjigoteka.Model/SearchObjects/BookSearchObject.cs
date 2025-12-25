using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.SearchObjects
{
    public class BookSearchObject : BaseSearchObject
    {
        public string? FTS { get; set; }
        public int? GenreId { get; set; }
        public int? LanguageId { get; set; }
        public bool Sandbox { get; set; } = false;
    }
}
