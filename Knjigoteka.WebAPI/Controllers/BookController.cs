using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Knjigoteka.WebAPI.Controllers
{
    [Route("api/[controller]")]
    public class BooksController
        : BaseCRUDController<BookResponse, BookSearchObject, BookInsert, BookUpdate>
    {
        public readonly IBookService _service;
        public BooksController(
            ILogger<BaseController<BookResponse, BookSearchObject>> logger,
            IBookService service)
            : base(logger, service)
        {
            _service = service;
        }
        [HttpGet("{id:int}/photo")]
        [AllowAnonymous]
        public async Task<IActionResult> GetPhoto(int id, [FromServices] DatabaseContext db)
        {
            var img = await db.Books
                .AsNoTracking()
                .IgnoreQueryFilters()
                .Where(b => b.Id == id)
                .Select(b => new { b.BookImage, b.BookImageContentType })
                .FirstOrDefaultAsync();

            if (img == null || img.BookImage == null || img.BookImage.Length == 0)
                return NotFound();

            var contentType = string.IsNullOrWhiteSpace(img.BookImageContentType)
                ? "image/png"
                : img.BookImageContentType;

            return File(img.BookImage, contentType);
        }

        [HttpPost("{id:int}/photo")]
        public async Task<IActionResult> UploadPhoto(int id, IFormFile file, [FromServices] DatabaseContext db)
        {
            var book = await db.Books.FindAsync(id);
            if (book == null) return NotFound();
            if (file == null || file.Length == 0) return BadRequest("No file.");

            using var ms = new MemoryStream();
            await file.CopyToAsync(ms);
            book.BookImage = ms.ToArray();
            book.BookImageContentType = file.ContentType;

            await db.SaveChangesAsync();
            return Ok();
        }
        [Authorize]
        [HttpGet("{id}/recommend")]
        public async Task<List<BookResponse>> Recommend(int id, [FromQuery] int take = 3)
       => await _service.RecommendAsync(id, take);
    }
}
