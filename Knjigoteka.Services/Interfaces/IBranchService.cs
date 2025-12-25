using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Stripe;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Interfaces
{
    public interface IBranchService
        : ICRUDService<BranchResponse, BranchSearchObject, BranchInsert, BranchUpdate>
    {
        Task<BranchReportResponse> GetBranchReportAsync(BranchReportRequest req);

    }
}
