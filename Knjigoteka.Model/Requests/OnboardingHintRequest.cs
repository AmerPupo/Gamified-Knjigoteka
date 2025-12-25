using Knjigoteka.Model.Helpers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Requests
{
    public class OnboardingHintRequest
    {
        public string ItemCode { get; set; } = string.Empty;
        public OnboardingItemType ItemType { get; set; }
    }
}
