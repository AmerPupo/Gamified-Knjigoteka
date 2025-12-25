using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.Services.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjigoteka.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class BranchesController
        : BaseCRUDController<BranchResponse, BranchSearchObject, BranchInsert, BranchUpdate>
    {
        public readonly IBranchService _service;

        public BranchesController(
            ILogger<BaseController<BranchResponse, BranchSearchObject>> logger,
            IBranchService service)
            : base(logger, service) {
            _service = service;
        }
        [HttpPost("{id}/report")]
        [Authorize(Roles = "Admin")]
        public async Task<BranchReportResponse> GetReport(int id, [FromBody] BranchReportRequest req)
        {
            req.BranchId = id;
            return await _service.GetBranchReportAsync(req);
        }

    }
}
