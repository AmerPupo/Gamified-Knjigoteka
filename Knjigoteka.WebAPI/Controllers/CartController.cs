using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjigoteka.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "User,Admin,Employee")]
    public class CartController : ControllerBase
    {
        private readonly ICartService _service;
        public CartController(ICartService service) => _service = service;

        [HttpGet]
        public Task<CartResponse> Get() => _service.GetAsync();

        [HttpPost]
        public Task<CartResponse> Upsert(CartItemUpsert dto) => _service.UpsertAsync(dto);

        [HttpDelete("{bookId:int}")]
        public async Task<IActionResult> Remove(int bookId)
            => await _service.RemoveAsync(bookId) ? NoContent() : NotFound();

        [HttpDelete]
        public Task Clear() => _service.ClearAsync();
    }
}
