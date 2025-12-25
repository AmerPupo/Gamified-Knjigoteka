using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjigoteka.WebAPI.Controllers
{
    [Route("api/[controller]")]
    public class LanguagesController
        : BaseCRUDController<LanguageResponse, LanguageSearchObject, LanguageInsert, LanguageUpdate>
    {
        public LanguagesController(
            ILogger<BaseController<LanguageResponse, LanguageSearchObject>> logger,
            ILanguageService service)
            : base(logger, service)
        {
        }
        [Authorize]
        [HttpGet("{id}")]
        public override Task<LanguageResponse> GetById(int id)
            => base.GetById(id);

        [Authorize(Roles = "Admin")]
        [HttpPost]
        public override Task<LanguageResponse> Insert([FromBody] LanguageInsert insert)
            => base.Insert(insert);

        [Authorize(Roles = "Admin")]
        [HttpPut("{id}")]
        public override Task<LanguageResponse> Update(int id, [FromBody] LanguageUpdate update)
            => base.Update(id, update);

        [Authorize(Roles = "Admin")]
        [HttpDelete("{id}")]
        public override Task<IActionResult> Delete(int id) => base.Delete(id);
    }
}
