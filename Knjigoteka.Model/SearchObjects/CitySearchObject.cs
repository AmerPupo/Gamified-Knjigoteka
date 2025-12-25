using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.SearchObjects
{
    public class CitySearchObject : BaseSearchObject
    {
        public string? FTS { get; set; } = null!;
    }
}
