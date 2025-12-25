using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

public class SaleService : ISaleService
{
    private readonly DatabaseContext _db;

    public SaleService(DatabaseContext db)
    {
        _db = db;
    }

    public async Task<SaleResponse> InsertAsync(SaleInsert request)
    {
        if (request.Items == null || request.Items.Count == 0)
            throw new Exception("Prodaja mora sadržavati barem jednu stavku.");

        var employee = await _db.Employees
            .Include(e => e.User)
            .FirstOrDefaultAsync(e => e.UserId == request.EmployeeId)
            ?? throw new Exception("Employee not found.");

        var branchId = employee.BranchId;

        var sale = new Sale
        {
            EmployeeId = employee.Id,
            SaleDate = DateTime.Now,
            TotalAmount = 0
        };
        await _db.SaveChangesAsync();

        foreach (var item in request.Items)
        {
            var bb = await _db.BookBranches
                .Include(b => b.Book)
                .FirstOrDefaultAsync(b => b.BranchId == branchId && b.BookId == item.BookId)
                ?? throw new Exception($"Knjiga (id={item.BookId}) nije dostupna u poslovnici!");

            if (item.Quantity <= 0)
                throw new Exception("Količina mora biti > 0!");

            if (item.Quantity > bb.QuantityForSale)
                throw new Exception($"Nema dovoljno knjiga '{bb.Book.Title}' na stanju (max {bb.QuantityForSale})!");

            bb.QuantityForSale -= item.Quantity;

            decimal unitPrice = bb.Book.Price;

            sale.Items.Add(new SaleItem
            {
                BookId = item.BookId,
                Quantity = item.Quantity,
                UnitPrice = unitPrice
            });
            await _db.SaveChangesAsync();

            sale.TotalAmount += unitPrice * item.Quantity;
        }

        _db.Sales.Add(sale);
        await _db.SaveChangesAsync();

        var full = await _db.Sales
            .Include(s => s.Employee).ThenInclude(e => e.User)
            .Include(s => s.Employee).ThenInclude(e => e.Branch)
            .Include(s => s.Items).ThenInclude(si => si.Book)
            .FirstOrDefaultAsync(s => s.Id == sale.Id);

        return MapToDto(full!);
    }

    public async Task<List<SaleResponse>> GetAllAsync(int? branchId = null, DateTime? dateFrom = null, DateTime? dateTo = null)
    {
        var q = _db.Sales
            .Include(s => s.Employee).ThenInclude(e => e.User)
            .Include(s => s.Employee).ThenInclude(e => e.Branch)
            .Include(s => s.Items).ThenInclude(i => i.Book)
            .AsQueryable();

        if (branchId.HasValue)
            q = q.Where(s => s.Employee.BranchId == branchId.Value);
        if (dateFrom.HasValue)
            q = q.Where(s => s.SaleDate >= dateFrom.Value);
        if (dateTo.HasValue)
            q = q.Where(s => s.SaleDate <= dateTo.Value);

        var sales = await q.OrderByDescending(s => s.SaleDate).ToListAsync();
        return sales.Select(MapToDto).ToList();
    }


    private SaleResponse MapToDto(Sale sale) => new SaleResponse
    {
        Id = sale.Id,
        EmployeeId = sale.EmployeeId,
        EmployeeName = $"{sale.Employee.User.FirstName} {sale.Employee.User.LastName}",
        BranchId = sale.Employee.BranchId,
        BranchName = sale.Employee.Branch.Name,
        SaleDate = sale.SaleDate,
        TotalAmount = sale.TotalAmount,
        Items = sale.Items.Select(i => new SaleItemResponse
        {
            Id = i.Id,
            BookId = i.BookId,
            BookTitle = i.Book.Title,
            Quantity = i.Quantity,
            UnitPrice = i.UnitPrice
        }).ToList()
    };

}
