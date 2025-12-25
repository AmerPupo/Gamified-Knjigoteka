using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Interfaces
{
    public interface ISaleService
    {
        Task<SaleResponse> InsertAsync(SaleInsert request);
        Task<List<SaleResponse>> GetAllAsync(int? branchId = null, DateTime? dateFrom = null, DateTime? dateTo = null);
    }

}
