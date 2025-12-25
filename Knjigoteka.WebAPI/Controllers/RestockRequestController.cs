using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjigoteka.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RestockRequestsController : BaseCRUDController<
        RestockRequestResponse, RestockRequestSearchObject, RestockRequestCreate, RestockRequestUpdate>
    {
        private readonly IRestockRequestService _service;

        public RestockRequestsController(
            ILogger<BaseController<RestockRequestResponse, RestockRequestSearchObject>> logger,
            IRestockRequestService service)
            : base(logger, service)
        {
            _service = service;
        }
        [Authorize(Roles = "Admin")]
        [HttpPost("{id:int}/approve")]
        public async Task<IActionResult> Approve(int id)
        {
            try
            {
                var ok = await _service.ApproveAsync(id);
                return ok ? Ok() : NotFound();
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }
        [Authorize(Roles = "Admin")]
        [HttpPost("{id:int}/reject")]
        public async Task<IActionResult> Reject(int id)
        {
            try
            {
                var ok = await _service.RejectAsync(id);
                return ok ? Ok() : NotFound();
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpGet("bybranch")]
        [Authorize(Roles = "Employee")]
        public async Task<ActionResult<List<RestockRequestResponse>>> GetByBranch([FromQuery] int? bookId = null)
        {
            var result = await _service.GetByBranchAsync(bookId);
            return Ok(result);
        }
        [Authorize(Roles = "Employee")]
        [HttpDelete("{id:int}")]
        public override async Task<IActionResult> Delete(int id)
        {
            try
            {
                var deleted = await _service.Delete(id);
                return deleted ? NoContent() : NotFound();
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

    }

}
