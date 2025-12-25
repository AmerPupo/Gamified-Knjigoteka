using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Helpers;
using Knjigoteka.Model.Responses;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Knjigoteka.Services.Services
{
    public class OnboardingService : IOnboardingService
    {
        private readonly DatabaseContext _db; // zamijeni sa svojim kontekstom

        public OnboardingService(DatabaseContext db)
        {
            _db = db;
        }

        public async Task<List<OnboardingItemStatus>> GetUserItemsAsync(int userId)
        {
            var definitions = OnboardingDefinitions.Items;
            var progress = await _db.OnboardingProgresses
                .Where(p => p.UserId == userId)
                .ToListAsync();
            var progressByKey = progress
                                .GroupBy(p => new { p.ItemCode, p.ItemType })
                                .ToDictionary(
                                    g => (g.Key.ItemCode, g.Key.ItemType),
                                    g => g
                                        .OrderByDescending(x => x.LastAttemptAt ?? DateTime.MinValue)
                                        .First()
                                );
            var result = definitions
                .Select(def =>
                {
                    progressByKey.TryGetValue((def.Code, def.ItemType), out var p);

                    return new OnboardingItemStatus
                    {
                        Code = def.Code,
                        Name = def.Name,
                        Description = def.Description,
                        ItemType = def.ItemType,
                        Order = def.Order,

                        IsCompleted = p?.IsCompleted ?? false,
                        Attempts = p?.Attempts ?? 0,
                        HintShown = p?.HintShown ?? false,

                        RequiredItemCodes = def.RequiredItemCodes?.ToList()
                            ?? new List<string>()
                    };
                })
                .OrderBy(x => x.Order)
                .ToList();

            return result;
        }

        public async Task<bool> HasCompletedOnboardingAsync(int userId)
        {
            var allItemCodes = OnboardingDefinitions.Items
                .Select(i => i.Code)
                .ToList();

            if (!allItemCodes.Any())
                return true;

            var completedCodes = await _db.OnboardingProgresses
                .Where(p => p.UserId == userId && p.IsCompleted)
                .Select(p => p.ItemCode)
                .ToListAsync();

            var completedSet = completedCodes.ToHashSet();

            return allItemCodes.All(code => completedSet.Contains(code));
        }

        public async Task MarkCompletedAsync(int userId, string itemCode, OnboardingItemType itemType)
        {
            await RegisterAttemptAsync(userId, itemCode, itemType, isSuccess: true);
        }

        public async Task<OnboardingItemStatus> RegisterAttemptAsync(
            int userId,
            string itemCode,
            OnboardingItemType itemType,
            bool isSuccess
        )
        {
            var def = OnboardingDefinitions.Items
                .FirstOrDefault(d => d.Code == itemCode && d.ItemType == itemType);

            if (def == null)
                throw new InvalidOperationException(
                    $"Nepoznat onboarding item: {itemCode} / {itemType}");

            var progress = await _db.OnboardingProgresses
                .FirstOrDefaultAsync(p =>
                    p.UserId == userId &&
                    p.ItemCode == itemCode &&
                    p.ItemType == itemType);

            if (progress == null)
            {
                progress = new OnboardingProgress
                {
                    UserId = userId,
                    ItemCode = itemCode,
                    ItemType = itemType,
                    Attempts = 0,
                    IsCompleted = false,
                    HintShown = false
                };
                _db.OnboardingProgresses.Add(progress);
            }
            progress.Attempts += 1;
            progress.LastAttemptAt = DateTime.UtcNow;
            if (isSuccess)
                progress.IsCompleted = true;

            await _db.SaveChangesAsync();
            return new OnboardingItemStatus
            {
                Code = def.Code,
                Name = def.Name,
                Description = def.Description,
                ItemType = def.ItemType,
                Order = def.Order,
                IsCompleted = progress.IsCompleted,
                Attempts = progress.Attempts,
                HintShown = progress.HintShown,
                RequiredItemCodes = def.RequiredItemCodes?.ToList() ?? new List<string>()
            };
        }

        public async Task<OnboardingItemStatus> MarkHintShownAsync(
            int userId,
            string itemCode,
            OnboardingItemType itemType
        )
        {
            var def = OnboardingDefinitions.Items
                .FirstOrDefault(d => d.Code == itemCode && d.ItemType == itemType);

            if (def == null)
                throw new InvalidOperationException(
                    $"Nepoznat onboarding item: {itemCode} / {itemType}");

            var progress = await _db.OnboardingProgresses
                .FirstOrDefaultAsync(p =>
                    p.UserId == userId &&
                    p.ItemCode == itemCode &&
                    p.ItemType == itemType);

            if (progress == null)
            {
                progress = new OnboardingProgress
                {
                    UserId = userId,
                    ItemCode = itemCode,
                    ItemType = itemType,
                    Attempts = 0,
                    IsCompleted = false,
                    HintShown = true,
                    LastAttemptAt = DateTime.UtcNow
                };

                _db.OnboardingProgresses.Add(progress);
            }
            else
            {
                progress.HintShown = true;
            }

            await _db.SaveChangesAsync();

            return new OnboardingItemStatus
            {
                Code = def.Code,
                Name = def.Name,
                Description = def.Description,
                ItemType = def.ItemType,
                Order = def.Order,
                IsCompleted = progress.IsCompleted,
                Attempts = progress.Attempts,
                HintShown = progress.HintShown,
                RequiredItemCodes = def.RequiredItemCodes?.ToList() ?? new List<string>()
            };
        }


    }
}
