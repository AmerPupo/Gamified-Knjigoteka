using Knjigoteka.Model.Helpers;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjigoteka.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class GenresController
     : BaseCRUDController<GenreResponse, GenreSearchObject, GenreInsert, GenreUpdate>
    {
        public GenresController(
            ILogger<BaseController<GenreResponse, GenreSearchObject>> logger,
            IGenreService service)
            : base(logger, service)
        { }

        [Authorize]
        [HttpGet]
        public override Task<PagedResult<GenreResponse>> Get([FromQuery] GenreSearchObject search)
            => base.Get(search);

        [Authorize]
        [HttpGet("{id}")]
        public override Task<GenreResponse> GetById(int id)
            => base.GetById(id);

        [Authorize(Roles = "Admin")]
        [HttpPost]
        public override Task<GenreResponse> Insert([FromBody] GenreInsert insert)
            => base.Insert(insert);

        [Authorize(Roles = "Admin")]
        [HttpPut("{id}")]
        public override Task<GenreResponse> Update(int id, [FromBody] GenreUpdate update)
            => base.Update(id, update);

        [Authorize(Roles = "Admin")]
        [HttpDelete("{id}")]
        public override Task<IActionResult> Delete(int id) => base.Delete(id);
    }

}
