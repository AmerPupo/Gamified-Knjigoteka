using Knjigoteka.Model.Helpers;
using Knjigoteka.Model.Responses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Interfaces
{
    public interface IOnboardingService
    {
        Task<List<OnboardingItemStatus>> GetUserItemsAsync(int userId);
        Task<bool> HasCompletedOnboardingAsync(int userId);
        Task MarkCompletedAsync(int userId, string itemCode, OnboardingItemType itemType);
        Task<OnboardingItemStatus> RegisterAttemptAsync(
    int userId,
    string itemCode,
    OnboardingItemType itemType,
    bool isSuccess
);

        Task<OnboardingItemStatus> MarkHintShownAsync(
            int userId,
            string itemCode,
            OnboardingItemType itemType
        );
    }
}
