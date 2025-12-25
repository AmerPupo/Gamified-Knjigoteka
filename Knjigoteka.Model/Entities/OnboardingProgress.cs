using Knjigoteka.Model.Helpers;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Model.Entities
{
    public class OnboardingProgress
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string ItemCode { get; set; } = string.Empty;
        public OnboardingItemType ItemType { get; set; }
        public bool IsCompleted { get; set; }
        public int Attempts { get; set; }
        public bool HintShown { get; set; }
        public DateTime? LastAttemptAt { get; set; }

        [ForeignKey(nameof(UserId))]
        public User User { get; set; } = null!;
    }
}
