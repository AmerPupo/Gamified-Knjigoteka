using Knjigoteka.Model;
using Knjigoteka.Model.Helpers;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;

namespace Knjigoteka.Services.Interfaces
{
    public interface IBranchInventoryService
    {
        Task<PagedResult<BranchInventoryResponse>> GetAsync(BranchInventorySearchObject search);
        Task UpsertAsync(int branchId, BranchInventoryUpsert request);
        Task<List<BranchInventoryResponse>> GetAvailabilityByBookIdAsync(int bookId, bool sandbox);
        Task<bool> DeleteAsync(int branchId, int bookId);
    }
}
