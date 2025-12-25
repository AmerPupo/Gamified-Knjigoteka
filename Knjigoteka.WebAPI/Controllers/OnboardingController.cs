using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Helpers;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.Services.Utilities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Knjigoteka.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles ="Employee")]
    public class OnboardingController : ControllerBase
    {
        private readonly IOnboardingService _onboardingService;
        private readonly IUserContext _userContext;
        public OnboardingController(IOnboardingService onboardingService, IUserContext userContext)
        {
            _onboardingService = onboardingService;
            _userContext = userContext;
        }
        private int GetCurrentUserId()
        {
            var idClaim = User.FindFirst(ClaimTypes.NameIdentifier)
                         ?? User.FindFirst("id");

            if (idClaim == null)
                throw new Exception("User id claim not found.");
            return int.Parse(idClaim.Value);
        }
        [HttpGet("overview")]
        public async Task<IActionResult> GetOverview()
        {
            var userId = GetCurrentUserId();
            var items = await _onboardingService.GetUserItemsAsync(userId);
            var hasCompleted = await _onboardingService.HasCompletedOnboardingAsync(userId);
            return Ok(new
            {
                hasCompletedOnboarding = hasCompleted,
                items
            });
        }
        public class CompleteRequest
        {
            public string ItemCode { get; set; } = string.Empty;
            public OnboardingItemType ItemType { get; set; }
        }
        [HttpPost("complete")]
        public async Task<IActionResult> Complete([FromBody] CompleteRequest request)
        {
            var userId = GetCurrentUserId();
            await _onboardingService.MarkCompletedAsync(
                userId,
                request.ItemCode,
                request.ItemType
            );
            return NoContent();
        }
        [HttpPost("attempt")]
        public async Task<ActionResult<OnboardingItemStatus>> RegisterAttempt(
        [FromBody] OnboardingAttemptRequest req)
        {
            var userId = _userContext.UserId;
            var status = await _onboardingService.RegisterAttemptAsync(
                userId,
                req.ItemCode,
                req.ItemType,
                req.Success
            );
            return Ok(status);
        }
        [HttpPost("hint-shown")]
        public async Task<ActionResult<OnboardingItemStatus>> MarkHintShown(
            [FromBody] OnboardingHintRequest req)
        {
            var userId = _userContext.UserId;
            var status = await _onboardingService.MarkHintShownAsync(
                userId,
                req.ItemCode,
                req.ItemType
            );
            return Ok(status);
        }
    }
}
