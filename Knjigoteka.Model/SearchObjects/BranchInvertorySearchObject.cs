using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.SearchObjects
{
    public class BranchInventorySearchObject : BaseSearchObject
    {
        // Full-Text Search across book fields
        public string? FTS { get; set; }

        // Facets
        public int BranchId { get; set; }
        public int BookId { get; set; }
        public bool? SupportsBorrowing { get; set; }
        public bool Sandbox { get; set; } = false;

    }
}
