using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/[controller]")]
public class BorrowingsController : ControllerBase
{
    private readonly IBorrowingService _service;
    public BorrowingsController(IBorrowingService service) => _service = service;

    [HttpPost]
    [Authorize(Roles = "Employee")]
    public async Task<ActionResult<BorrowingResponse>> Create(BorrowingCreate req)
    {
        try
        {
            var result = await _service.CreateAsync(req);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost("{id:int}/return")]
    [Authorize(Roles = "Employee")]
    public async Task<IActionResult> Return(int id)
    {
        try
        {
            var ok = await _service.ReturnAsync(id);
            return ok ? Ok() : NotFound();
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpGet("mine")]
    [Authorize]
    public async Task<List<BorrowingResponse>> Mine() => await _service.GetMineAsync();

    [HttpGet("user/{userId:int}")]
    [Authorize(Roles = "Employee")]
    public async Task<List<BorrowingResponse>> ByUser(int userId) => await _service.GetByUserAsync(userId);

    [HttpGet("branch/{branchId:int}")]
    [Authorize(Roles = "Admin, Employee")]
    public async Task<ActionResult<List<BorrowingResponse>>> ByBranch( int? branchId,
    [FromQuery] bool sandbox = false)
    {
        var result = await _service.GetByBranchAsync(branchId, sandbox);
        return Ok(result);
    }

    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<List<BorrowingResponse>> All() => await _service.GetAllAsync();
    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Employee")]
    public async Task<bool> Delete(int id) => await _service.DeleteAsync(id);
}
