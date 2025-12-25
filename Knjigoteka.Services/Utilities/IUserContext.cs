using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Utilities
{
    public interface IUserContext
    {
        int UserId { get; }
        string? Role { get; }
        string? Email { get; }
        string? FullName { get; }
        int? BranchId { get; }
        int? SandboxBranchId { get; }
        int? EmployeeId { get; }
    }
}
