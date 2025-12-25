namespace Knjigoteka.WebAPI.Controllers
{
    using Knjigoteka.Model.Requests;
    using Knjigoteka.Model.Responses;
    using Knjigoteka.Services.Interfaces;
    using Microsoft.AspNetCore.Authorization;
    using Microsoft.AspNetCore.Mvc;

    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class NotificationRequestController : ControllerBase
    {
        private readonly INotificationRequestService _service;
        public NotificationRequestController(INotificationRequestService service) => _service = service;

        [HttpPost]
        public async Task<ActionResult<NotificationRequestResponse>> Create(NotificationRequestCreate dto)
        {
            try
            {
                var result = await _service.CreateAsync(dto);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpGet("mine")]
        public Task<List<NotificationRequestResponse>> MyRequests() => _service.GetMyRequestsAsync();

        [Authorize(Roles = "Admin,Employee")]
        [HttpGet]
        public Task<List<NotificationRequestResponse>> All() => _service.GetAllAsync();

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Delete(int id)
        {
            var ok = await _service.DeleteAsync(id);
            return ok ? NoContent() : NotFound();
        }
    }

}
