using Knjigoteka.Model;
using Knjigoteka.Model.Helpers;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.Services.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.ComponentModel.DataAnnotations;

namespace Knjigoteka.WebAPI.Controllers
{
    [Route("api/branches/inventory")]
    [ApiController]
    public class BranchInventoryController : ControllerBase
    {
        private readonly IBranchInventoryService _service;
        private readonly ILogger<BranchInventoryController> _logger;

        public BranchInventoryController(IBranchInventoryService service, ILogger<BranchInventoryController> logger)
        {
            _service = service;
            _logger = logger;
        }

        [HttpGet]
        public async Task<PagedResult<BranchInventoryResponse>> Get([FromQuery] BranchInventorySearchObject search)
            => await _service.GetAsync(search);


        [HttpPut]
        [Authorize(Roles = "Employee")]
        public async Task<IActionResult> Upsert(
                   [Required] int branchId,
                   [FromBody] BranchInventoryUpsert request)
        {
            try
            {
                if (request == null)
                {
                    return BadRequest("Request body cannot be null");
                }

                await _service.UpsertAsync(branchId, request);
                return Ok("Inventory updated successfully");
            }
            catch (KeyNotFoundException ex)
            {
                _logger.LogWarning(ex, "Book not found for branch {BranchId}, book {BookId}", branchId, request?.BookId);
                return NotFound(ex.Message);
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogWarning(ex, "Invalid operation for branch {BranchId}, book {BookId}", branchId, request?.BookId);
                return BadRequest(ex.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred while upserting inventory for branch {BranchId}", branchId);
                return StatusCode(500, "An error occurred while processing your request");
            }
        }
        [HttpGet("availability/{bookId}")]
        public async Task<IActionResult> GetAvailabilityByBookId(int bookId, [FromQuery] bool sandbox = false)
        {
            var result = await _service.GetAvailabilityByBookIdAsync(bookId, sandbox);
            return Ok(result);
        }

        [HttpDelete("{bookId:int}")]
        public async Task<IActionResult> Delete(int branchId, int bookId)
        {
            var ok = await _service.DeleteAsync(branchId, bookId);
            return ok ? NoContent() : NotFound();
        }
    }
}
