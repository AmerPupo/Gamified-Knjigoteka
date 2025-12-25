using Knjigoteka.Model.Entities;
using Knjigoteka.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Knjigoteka.WebAPI.Controllers
{
    [Route("api/penalties")]
    [ApiController]
    public class PenaltyController : ControllerBase
    {
        private readonly IPenaltyService _penaltyService;

        public PenaltyController(IPenaltyService penaltyService)
        {
            _penaltyService = penaltyService;
        }

        [HttpGet("{userId:int}/points")]
        public async Task<int> GetPoints(int userId)
            => await _penaltyService.GetPointsAsync(userId);

        [HttpGet("{userId:int}")]
        public async Task<List<Penalty>> GetUserPenalties(int userId)
            => await _penaltyService.GetUserPenaltiesAsync(userId);
    }

}
