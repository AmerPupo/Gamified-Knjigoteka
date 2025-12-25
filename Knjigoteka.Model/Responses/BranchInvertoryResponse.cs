using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Responses
{
    public class BranchInventoryResponse
    {
        public int BookId { get; set; }
        public int BranchId { get; set; }
        public string? BranchName { get; set; }
        public string? BranchAdress { get; set; }
        public string Title { get; set; } = null!;
        public string Author { get; set; } = null!;
        public string GenreName { get; set; } = null!;
        public string LanguageName { get; set; } = null!;
        public decimal Price { get; set; }
        public string PhotoEndpoint { get; set; } = null!;
        public bool SupportsBorrowing { get; set; }
        public int QuantityForBorrow { get; set; }
        public int QuantityForSale { get; set; }
    }
}
