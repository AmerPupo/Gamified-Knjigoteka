using Knjigoteka.Model.Requests;
using Knjigoteka.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SaleController : ControllerBase
{
    private readonly ISaleService _service;
    public SaleController(ISaleService service)
    {
        _service = service;
    }

    [HttpPost]
    public async Task<ActionResult> Create([FromBody] SaleInsert request)
    {
        try
        {
            var res = await _service.InsertAsync(request);
            return Ok(res);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet]
    public async Task<ActionResult> GetAll([FromQuery] int? branchId, [FromQuery] DateTime? dateFrom, [FromQuery] DateTime? dateTo)
    {
        var res = await _service.GetAllAsync(branchId, dateFrom, dateTo);
        return Ok(res);
    }
}
