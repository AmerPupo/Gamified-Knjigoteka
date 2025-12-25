using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Responses
{
    public class BookResponse
    {
        public int Id { get; set; }
        public string Title { get; set; } = null!;
        public string Author { get; set; } = null!;
        public int GenreId { get; set; }
        public string GenreName { get; set; } = null!;
        public int LanguageId { get; set; }
        public string LanguageName { get; set; } = null!;
        public string ISBN { get; set; } = null!;
        public int Year { get; set; }
        public int CentralStock { get; set; }
        public int CalculatedTotalQuantity { get; set; }
        public string ShortDescription { get; set; } = null!;
        public decimal Price { get; set; }
        public bool HasImage { get; set; }
        public string PhotoEndpoint { get; set; } = null!;
        public double? AverageRating { get; set; }
        public int? ReviewsCount { get; set; }
    }
}
