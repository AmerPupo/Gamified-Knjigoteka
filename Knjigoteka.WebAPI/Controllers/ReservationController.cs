using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.Services.Utilities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjigoteka.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ReservationsController
        : BaseCRUDController<ReservationResponse, ReservationSearchObject, ReservationRequest, ReservationRequest>
    {
        private readonly IReservationService _reservationService;
        private readonly IUserContext _userContext;

        public ReservationsController(
            ILogger<BaseController<ReservationResponse, ReservationSearchObject>> logger,
            IReservationService service,
            IUserContext userContext)
            : base(logger, service)
        {
            _reservationService = service;
            _userContext = userContext;
        }

        [HttpDelete("{id:int}/cancel")]
        [Authorize] 
        public async Task<IActionResult> Cancel(int id)
        {
            var dto = await _reservationService.GetById(id);
            if (dto == null) return NotFound();

            var isOwner = dto.UserId == _userContext.UserId;
            var isStaff = _userContext.Role == "Admin" || _userContext.Role == "Employee";

            if (!isOwner && !isStaff) return Forbid();

            if (isOwner && !string.Equals(dto.Status, ReservationStatus.Pending.ToString(), StringComparison.OrdinalIgnoreCase))
                return BadRequest("You can only cancel reservations that are Pending.");

            var deleted = await _reservationService.Delete(id);
            return deleted ? NoContent() : NotFound();
        }





        [HttpPost("expire")]
        [Authorize(Roles = "Admin,Employee")]
        public async Task<IActionResult> ExpirePending()
        {
            try
            {
                var count = await _reservationService.ExpirePendingReservationsAsync();
                return Ok(new { expired = count });
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }
    }
}
