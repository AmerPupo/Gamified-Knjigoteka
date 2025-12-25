using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Interfaces
{
    public interface IBorrowingService
    {
        Task<BorrowingResponse> CreateAsync(BorrowingCreate request);
        Task<bool> ReturnAsync(int borrowingId);
        Task<List<BorrowingResponse>> GetMineAsync();
        Task<List<BorrowingResponse>> GetByUserAsync(int userId);
        Task<List<BorrowingResponse>> GetByBranchAsync(int? branchId, bool sandbox);
        Task<List<BorrowingResponse>> GetAllAsync();
        Task<bool> DeleteAsync(int id);
    }


}
