using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Helpers
{
    public class CurrentYearRangeAttribute : RangeAttribute
    {
        public CurrentYearRangeAttribute(int minimum)
            : base(minimum, DateTime.Now.Year)
        {
            this.ErrorMessage = $"Please enter a valid year between {minimum} and {DateTime.Now.Year}.";
        }
    }
}
