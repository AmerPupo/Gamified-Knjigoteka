using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.Services.Services;
using Microsoft.EntityFrameworkCore;

public class EmployeeService
    : BaseCRUDService<EmployeeResponse, EmployeeSearchObject, EmployeeInsert, EmployeeUpdate, Employee>, IEmployeeService
{
    public EmployeeService(DatabaseContext context) : base(context) { }

    protected override IQueryable<Employee> AddInclude(IQueryable<Employee> query)
        => query.Include(e => e.User).Include(e => e.Branch);

    protected override IQueryable<Employee> ApplyFilter(IQueryable<Employee> query, EmployeeSearchObject? search)
    {
        query = query.Where(e => e.IsActive);

        if (search == null) return query;

        if (!string.IsNullOrWhiteSpace(search.NameFTS))
        {
            query = query.Where(e =>
                (e.User.FirstName + " " + e.User.LastName).Contains(search.NameFTS));
        }
        if (search.BranchId.HasValue)
            query = query.Where(e => e.BranchId == search.BranchId.Value);

        if (search.HiredAfter.HasValue)
            query = query.Where(e => e.EmploymentDate >= search.HiredAfter.Value);

        if (search.HiredBefore.HasValue)
            query = query.Where(e => e.EmploymentDate <= search.HiredBefore.Value);

        return query;
    }
    public override async Task<EmployeeResponse> Insert(EmployeeInsert request)
    {
        var employee = MapToEntity(request);

        var user = await _context.Users.FindAsync(request.UserId)
            ?? throw new Exception("User not found.");
        user.RoleId = 2;

        await _context.Employees.AddAsync(employee);
        await _context.SaveChangesAsync();

        var full = await _context.Employees
            .Include(e => e.User)
            .Include(e => e.Branch)
            .FirstOrDefaultAsync(e => e.Id == employee.Id);

        return MapToDto(full!);
    }
    public override async Task<EmployeeResponse> Update(int id, EmployeeUpdate request)
    {
        var employee = await _context.Employees
            .Include(e => e.User)   
            .Include(e => e.Branch) 
            .FirstOrDefaultAsync(e => e.Id == id)
            ?? throw new Exception("Employee not found.");

        MapToEntity(request, employee);
        await _context.SaveChangesAsync();

        if (employee.User == null)
            employee.User = await _context.Users.FindAsync(employee.UserId);
        if (employee.Branch == null)
            employee.Branch = await _context.Branches.FindAsync(employee.BranchId);

        return MapToDto(employee);
    }

    public override async Task<bool> Delete(int id)
    {
        var employee = await _context.Employees.FindAsync(id);
        if (employee == null)
            return false;

        employee.IsActive = false;

        var user = await _context.Users.FindAsync(employee.UserId);
        if (user != null)
            user.RoleId = 3;

        await _context.SaveChangesAsync();
        return true;
    }

    protected override EmployeeResponse MapToDto(Employee e)
        => new EmployeeResponse
        {
            Id = e.Id,
            UserId = e.UserId,
            FullName = $"{e.User.FirstName} {e.User.LastName}",
            BranchId = e.BranchId,
            BranchName = e.Branch.Name,
            EmploymentDate = e.EmploymentDate,
            IsActive = e.IsActive
        };

    protected override Employee MapToEntity(EmployeeInsert req)
        => new Employee
        {
            UserId = req.UserId,
            BranchId = req.BranchId,
            EmploymentDate = DateTime.Now,
            IsActive = true
        };

    protected override void MapToEntity(EmployeeUpdate req, Employee entity)
    {
        entity.BranchId = req.BranchId;
    }
}
