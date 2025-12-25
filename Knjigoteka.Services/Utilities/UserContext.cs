using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Utilities
{
    public class UserContext : IUserContext
    {
        private readonly IHttpContextAccessor _http;

        public UserContext(IHttpContextAccessor http) => _http = http;

        private ClaimsPrincipal? Principal => _http.HttpContext?.User;

        public int UserId
        {
            get
            {
                var raw =
                    Principal?.FindFirstValue(ClaimTypes.NameIdentifier) ??
                    Principal?.FindFirstValue("sub");
                if (!int.TryParse(raw, out var id) || id <= 0)
                    throw new UnauthorizedAccessException("Missing or invalid user id claim.");
                return id;
            }
        }

        public string? Role => Principal?.FindFirstValue(ClaimTypes.Role);
        public string? Email => Principal?.FindFirstValue(ClaimTypes.Email);
        public string? FullName => Principal?.FindFirstValue(ClaimTypes.Name);
        public int? BranchId =>
            int.TryParse(Principal?.FindFirstValue("branchId"), out var id) ? id : (int?)null;
        public int? SandboxBranchId =>
    int.TryParse(Principal?.FindFirstValue("sandboxBranchId"), out var id) ? id : (int?)null;
        public int? EmployeeId =>
            int.TryParse(Principal?.FindFirstValue("employeeId"), out var id) ? id: (int?)null;

    }
}
