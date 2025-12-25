using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.SearchObjects
{
    public class OrderSearchObject :  BaseSearchObject
    {
        public  int OrderId { get; set; }
        public int BookId {  get; set; }
    }
}
