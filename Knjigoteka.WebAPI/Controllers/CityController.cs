using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjigoteka.WebAPI.Controllers
{
    [Authorize(Roles = "Admin")]
    [Route("api/[controller]")]
    [ApiController]
    public class CityController
        : BaseCRUDController<CityResponse, CitySearchObject, CityInsert, CityUpdate>
    {
        public CityController(
            ILogger<BaseController<CityResponse, CitySearchObject>> logger,
            ICityService service)
            : base(logger, service)
        { }
    }
}
