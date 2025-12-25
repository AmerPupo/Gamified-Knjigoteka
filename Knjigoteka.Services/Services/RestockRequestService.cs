using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Helpers;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.Services.Utilities;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Services
{
    public class RestockRequestService :
        BaseCRUDService<RestockRequestResponse, RestockRequestSearchObject, RestockRequestCreate, RestockRequestUpdate, RestockRequest>,
        IRestockRequestService
    {
        private readonly DatabaseContext _context;
        private readonly IUserContext _user;

        public RestockRequestService(DatabaseContext context, IUserContext user)
            : base(context)
        {
            _context = context;
            _user = user;
        }

        protected override IQueryable<RestockRequest> AddInclude(IQueryable<RestockRequest> query)
        {
            return query
                .Include(r => r.Book)
                .Include(r => r.Branch)
                .Include(r => r.Employee)
                .ThenInclude(e => e.User);
        }

        protected override IQueryable<RestockRequest> ApplyFilter(IQueryable<RestockRequest> query, RestockRequestSearchObject? search)
        {
            query = query.OrderBy(o => o.Status);

            if (search == null) return query;
            if (search.BookId.HasValue)
                query = query.Where(r => r.BookId == search.BookId.Value);
            if (search.BranchId.HasValue)
                query = query.Where(r => r.BranchId == search.BranchId.Value);
            if (search.EmployeeId.HasValue)
                query = query.Where(r => r.EmployeeId == search.EmployeeId.Value);
            if (search.Status.HasValue)
                query = query.Where(r => r.Status == search.Status.Value);
            return query;
        }
        public async Task<List<RestockRequestResponse>> GetByBranchAsync(int?  bookId)
        {
            var branchId = _user.BranchId ?? throw new UnauthorizedAccessException("Employee must have a branch.");

            var query = AddInclude(_context.RestockRequests)
                .Where(r => r.BranchId == branchId && r.Status == RestockRequestStatus.Approved)
                .AsQueryable();

            if (bookId.HasValue)
                query = query.Where(r => r.BookId == bookId.Value);

            var list = await query.ToListAsync();
            return list.Select(MapToDto).ToList();
        }
        protected override RestockRequestResponse MapToDto(RestockRequest e)
        {
            return new RestockRequestResponse
            {
                Id = e.Id,
                BookId = e.BookId,
                BookTitle = e.Book?.Title ?? "",
                BranchId = e.BranchId,
                BranchName = e.Branch?.Name ?? "",
                EmployeeId = e.EmployeeId,
                EmployeeName = e.Employee?.User != null
                ? $"{e.Employee.User.FirstName} {e.Employee.User.LastName}"
                : "",
                RequestedAt = e.RequestDate,
                QuantityRequested = e.QuantityRequested,
                Status = e.Status
            };
        }

        protected override RestockRequest MapToEntity(RestockRequestCreate req)
        {
            int employeeId = _user.EmployeeId ?? throw new UnauthorizedAccessException();
            int branchId = _user.BranchId ?? throw new UnauthorizedAccessException();

            return new RestockRequest
            {
                BookId = req.BookId,
                BranchId = branchId,
                EmployeeId = employeeId,
                RequestDate = DateTime.Now,
                QuantityRequested = req.QuantityRequested,
                Status = RestockRequestStatus.Pending
            };
        }
        public override async Task<RestockRequestResponse> Insert(RestockRequestCreate request)
        {
            var centralStock = await _context.Books
                .Where(b => b.Id == request.BookId)
                .Select(b => b.CentralStock)
                .FirstOrDefaultAsync();

            if (centralStock < request.QuantityRequested)
                throw new Exception($"Nema dovoljno knjiga na centralnom skladištu. Maksimalno dostupno: {centralStock}.");

            if (request.QuantityRequested <= 0)
                throw new Exception("Broj knjiga mora biti veći od nule.");

            var entity = MapToEntity(request);
            _context.RestockRequests.Add(entity);
            await _context.SaveChangesAsync();

            var full = await AddInclude(_context.RestockRequests)
                         .FirstOrDefaultAsync(r => r.Id == entity.Id)
                         ?? throw new Exception("Inserted entity not found.");

            return MapToDto(full);
        }

        public override async Task<PagedResult<RestockRequestResponse>> Get(RestockRequestSearchObject? search = null)
        {
            if (_user.Role == "Admin")
            {
                return await base.Get(search);
            }

            throw new UnauthorizedAccessException("Role not allowed to view restock requests.");
        }

        protected override void MapToEntity(RestockRequestUpdate req, RestockRequest entity)
        {
            entity.QuantityRequested = req.QuantityRequested;
        }

        public async Task<bool> ApproveAsync(int id)
        {
            var entity = await _context.RestockRequests.Include(r => r.Book)
                .FirstOrDefaultAsync(r => r.Id == id)
                ?? throw new KeyNotFoundException("Request not found.");

            if (entity.Status != RestockRequestStatus.Pending)
                throw new InvalidOperationException("Request already processed.");

            entity.Status = RestockRequestStatus.Approved;
            entity.Book.CentralStock -= entity.QuantityRequested;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> RejectAsync(int id)
        {
            var entity = await _context.RestockRequests.FindAsync(id)
                ?? throw new KeyNotFoundException("Request not found.");

            if (entity.Status != RestockRequestStatus.Pending)
                throw new InvalidOperationException("Request already processed.");

            entity.Status = RestockRequestStatus.Rejected;
            await _context.SaveChangesAsync();
            return true;
        }
        public override async Task<bool> Delete(int id)
        {
            var entity = await _context.RestockRequests.FindAsync(id);

            if (entity == null)
                return false;

            if (_user.Role == "Employee")
            {
                if (entity.EmployeeId != _user.EmployeeId)
                    throw new UnauthorizedAccessException("You can only cancel your own restock requests.");
                if (entity.Status != RestockRequestStatus.Pending)
                    throw new InvalidOperationException("Only pending requests can be cancelled.");
            }

            _context.RestockRequests.Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }

    }

}
