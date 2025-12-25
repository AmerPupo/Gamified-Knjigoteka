using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Knjigoteka.Services.Services
{
    public class BranchService
        : BaseCRUDService<BranchResponse, BranchSearchObject, BranchInsert, BranchUpdate, Branch>, IBranchService
    {
        public BranchService(DatabaseContext context) : base(context) { }

        protected override IQueryable<Branch> ApplyFilter(IQueryable<Branch> query, BranchSearchObject? search)
        {
            if (search == null) return query;

            if (!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(b => b.Name.Contains(search.FTS) || 
                b.Address.Contains(search.FTS) ||
                b.City.Name.Contains(search.FTS));

            return query;
        }
        public override async Task<BranchResponse> GetById(int id)
        {
            var entity = await _context.Branches
                .Include(b => b.City)
                .FirstOrDefaultAsync(b => b.Id == id)
                ?? throw new KeyNotFoundException("Branch not found.");

            return MapToDto(entity);
        }
        protected override IQueryable<Branch> AddInclude(IQueryable<Branch> query)
        {
            return query
                .Include(b => b.City);
        }
        public override async Task<BranchResponse> Update(int id, BranchUpdate request)
        {
            var entity = await _context.Branches
                .Include(b => b.City)
                .FirstOrDefaultAsync(b => b.Id == id)
                ?? throw new Exception("Branch not found.");

            MapToEntity(request, entity);
            await _context.SaveChangesAsync();
            await _context.Entry(entity).Reference(b => b.City).LoadAsync();
            return MapToDto(entity);
        }
        public async Task<BranchReportResponse> GetBranchReportAsync(BranchReportRequest req)
        {
            var branch = await _context.Branches.FindAsync(req.BranchId)
                ?? throw new Exception("Branch not found!");

            var from = req.From ?? DateTime.MinValue;
            var to = req.To ?? DateTime.MaxValue;

            var sold = await _context.Sales
                .Include(s => s.Items)
                .Include(s => s.Employee) 
                .Where(x => x.Employee.BranchId == req.BranchId && x.SaleDate >= from && x.SaleDate <= to)
                .ToListAsync();

            var borrowed = await _context.Borrowings
                .Where(x => x.BranchId == req.BranchId && x.BorrowedAt >= from && x.BorrowedAt <= to)
                .ToListAsync();

            var totalSold = sold.Sum(s => s.Items.Sum(si => si.Quantity));
            var totalBorrowed = borrowed.Count;

            var soldPerDay = sold
                .GroupBy(s => s.SaleDate.Date)
                .Select(g => new { Date = g.Key, Count = g.Sum(s => s.Items.Sum(si => si.Quantity)) })
                .ToDictionary(x => x.Date, x => x.Count);

            var borrowedPerDay = borrowed
                .GroupBy(b => b.BorrowedAt.Date)
                .Select(g => new { Date = g.Key, Count = g.Count() })
                .ToDictionary(x => x.Date, x => x.Count);

            var allDates = soldPerDay.Keys.Union(borrowedPerDay.Keys).Distinct().OrderBy(d => d).ToList();

            var entries = allDates
                .Select(d => new BranchReportEntry
                {
                    Date = d,
                    Sold = soldPerDay.ContainsKey(d) ? soldPerDay[d] : 0,
                    Borrowed = borrowedPerDay.ContainsKey(d) ? borrowedPerDay[d] : 0
                }).ToList();

            return new BranchReportResponse
            {
                BranchId = branch.Id,
                BranchName = branch.Name,
                TotalSold = totalSold,
                TotalBorrowed = totalBorrowed,
                Entries = entries
            };
        }


        public override async Task<BranchResponse> Insert(BranchInsert request)
        {
            var entity = MapToEntity(request);
            await _context.Set<Branch>().AddAsync(entity);
            await _context.SaveChangesAsync();

            var reloaded = await _context.Branches
                .Include(b => b.City)
                .FirstOrDefaultAsync(b => b.Id == entity.Id);

            return MapToDto(reloaded!);
        }
        protected override BranchResponse MapToDto(Branch entity) => new()
        {
            Id = entity.Id,
            Name = entity.Name,
            CityId = entity.CityId,
            CityName = entity.City.Name,
            Address = entity.Address,
            PhoneNumber = entity.PhoneNumber,
            OpeningTime = entity.OpeningTime,
            ClosingTime = entity.ClosingTime
        };

        protected override Branch MapToEntity(BranchInsert request) => new()
        {
            Name = request.Name,
            CityId = request.CityId,
            Address = request.Address,
            PhoneNumber = request.PhoneNumber,
            OpeningTime = request.OpeningTime,
            ClosingTime = request.ClosingTime
        };

        protected override void MapToEntity(BranchUpdate request, Branch entity)
        {
            entity.Name = request.Name;
            entity.CityId = request.CityId;
            entity.Address = request.Address;
            entity.PhoneNumber = request.PhoneNumber;
            entity.OpeningTime = request.OpeningTime;
            entity.ClosingTime = request.ClosingTime;
        }
    }
}
