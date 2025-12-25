using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Interfaces
{
    public interface IRestockRequestService :
        ICRUDService<RestockRequestResponse, RestockRequestSearchObject, RestockRequestCreate, RestockRequestUpdate>
    {
        Task<bool> ApproveAsync(int id);
        Task<bool> RejectAsync(int id);
        Task<List<RestockRequestResponse>> GetByBranchAsync(int? bookId);
    }

}
