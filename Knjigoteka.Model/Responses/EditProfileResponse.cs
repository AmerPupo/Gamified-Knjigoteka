using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Responses
{
    public class EditProfileResponse
    {
        public string Token { get; set; }
        public DateTime Expires { get; set; }
    }

}
