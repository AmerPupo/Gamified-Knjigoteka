using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.Services.Utilities;
using Knjigoteka.WebAPI.Controllers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ReviewController : BaseCRUDController<ReviewResponse, ReviewSearchObject, ReviewInsert, ReviewUpdate>
{
    private readonly IReviewService _service;
    private readonly IUserContext _user;

    public ReviewController(
        ILogger<BaseController<ReviewResponse, ReviewSearchObject>> logger,
        IReviewService service,
        IUserContext user)
        : base(logger, service)
    {
        _service = service;
        _user = user;
    }

    [HttpGet("book/{bookId:int}")]
    [AllowAnonymous]
    public async Task<List<ReviewResponse>> GetByBook(int bookId)
        => await _service.GetByBookAsync(bookId);

    [HttpGet("mine")]
    public async Task<List<ReviewResponse>> GetMine()
        => await _service.GetByUserAsync(_user.UserId);
 


}
