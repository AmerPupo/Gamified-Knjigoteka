using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Helpers
{
    public class OnboardingItemDefinition
    {
        public string Code { get; set; } = string.Empty;    
        public string Name { get; set; } = string.Empty;      
        public string Description { get; set; } = string.Empty;
        public OnboardingItemType ItemType { get; set; }      
        public int Order { get; set; }                        
        public List<string> RequiredItemCodes { get; set; } = new(); 
    }
}
