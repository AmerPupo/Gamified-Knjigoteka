using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;

namespace Knjigoteka.Services.Interfaces
{

    public interface IEmployeeService : ICRUDService<EmployeeResponse, EmployeeSearchObject, EmployeeInsert, EmployeeUpdate>
    {
    }

}
