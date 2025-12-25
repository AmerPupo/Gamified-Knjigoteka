using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.WebAPI.Controllers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = "Admin")]
public class EmployeeController : BaseCRUDController<EmployeeResponse, EmployeeSearchObject, EmployeeInsert, EmployeeUpdate>
{
    public EmployeeController(
        ILogger<BaseController<EmployeeResponse, EmployeeSearchObject>> logger,
        IEmployeeService service
    ) : base(logger, service) { }
}
