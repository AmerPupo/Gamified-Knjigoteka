using Knjigoteka.Model;
using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Helpers;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using RabbitMQ.Client;
using System.Net;
using System.Text;

namespace Knjigoteka.Services.Services
{
    public class BranchInventoryService : IBranchInventoryService
    {
        private readonly DatabaseContext _context;
        //private readonly IRabbitMQService _rabbitMQConnectionManager;
        //private readonly RabbitMQ.Client.IModel _channel;
        //private readonly string _queueName = Environment.GetEnvironmentVariable("RABBITMQ_QUEUE") ?? "mailqueue";

        public BranchInventoryService(DatabaseContext context/*, IRabbitMQService rabbitMQConnectionManager*/)
        {
            _context = context;
            //_rabbitMQConnectionManager = rabbitMQConnectionManager;
            //_channel = rabbitMQConnectionManager.GetChannel();
        }

        public async Task<PagedResult<BranchInventoryResponse>> GetAsync(BranchInventorySearchObject search)
        {
            var q = _context.BookBranches
                .Include(bb => bb.Book).ThenInclude(b => b.Genre)
                .Include(bb => bb.Book).ThenInclude(b => b.Language)
                .Include(bb => bb.Branch).ThenInclude(b => b.City)
                .OrderBy(a => a.Book.Title)
                .AsQueryable();
            if (search.Sandbox)
            {
                q = q.IgnoreQueryFilters()
                     .Where(bb => bb.IsSandbox);
            }
            if (string.IsNullOrWhiteSpace(search.FTS)
                && search.BranchId <= 0
                && search.BookId <= 0)
            {
                throw new ArgumentException("At least one search parameter expected.");
            }


            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.FTS))
                {
                    q = q.Where(bb =>
                        bb.Book.Title.Contains(search.FTS) ||
                        bb.Book.Author.Contains(search.FTS));
                }
                if (search.BranchId > 0)
                    q = q.Where(bb => bb.BranchId == search.BranchId);

                if (search.BookId > 0)
                    q = q.Where(bb => bb.BookId == search.BookId);
                if (search.SupportsBorrowing.HasValue)
                    q = q.Where(bb => bb.SupportsBorrowing == search.SupportsBorrowing);
            }

            var page = search?.Page ?? 1;
            var pageSize = search?.PageSize ?? 100;
            var skip = (page - 1) * pageSize;

            var total = await q.CountAsync();

            var items = await q
                .OrderBy(bb => bb.Book.Title)
                .Skip(skip)
                .Take(pageSize)
                .Select(bb => new BranchInventoryResponse
                {
                    BookId = bb.BookId,
                    BranchId = bb.BranchId,
                    BranchName = bb.Branch.Name ?? "Nepoznata filiala",
                    BranchAdress = (bb.Branch.Address ?? "Nepoznata adresa")
                                    + ((bb.Branch.City != null && bb.Branch.City.Name != null) ? ", " + bb.Branch.City.Name : ""),
                    Title = bb.Book.Title ?? "Nepoznat naslov",
                    Author = bb.Book.Author ?? "Nepoznat autor",
                    GenreName = bb.Book.Genre != null ? bb.Book.Genre.Name ?? "Nepoznat žanr" : "Nepoznat žanr",
                    LanguageName = bb.Book.Language != null ? bb.Book.Language.Name ?? "Nepoznat jezik" : "Nepoznat jezik",
                    Price = bb.Book.Price,
                    PhotoEndpoint = $"/books/{bb.BookId}/photo",
                    SupportsBorrowing = bb.SupportsBorrowing,
                    QuantityForBorrow = bb.QuantityForBorrow,
                    QuantityForSale = bb.QuantityForSale
                })
                .ToListAsync();

            return new PagedResult<BranchInventoryResponse>
            {
                Items = items,
                TotalCount = total
            };
        }

        public async Task UpsertAsync(int branchId, BranchInventoryUpsert request)
        {
            var book = await _context.Books
                .Include(b => b.BookBranches)
                .FirstOrDefaultAsync(b => b.Id == request.BookId)
                ?? throw new KeyNotFoundException("Book not found.");

            var bb = await _context.BookBranches
                .Include(b => b.Branch)
                .FirstOrDefaultAsync(x => x.BranchId == branchId && x.BookId == request.BookId)
                ;

            var restockRequest = await _context.RestockRequests
                .Where(r => r.BranchId == branchId
                         && r.BookId == request.BookId
                         && r.Status == RestockRequestStatus.Approved)
                .OrderBy(r => r.RequestDate)
                .FirstOrDefaultAsync();

            if (restockRequest == null)
                throw new InvalidOperationException("Nema odobrenog restock requesta za ovu knjigu.");

            int totalAdd = (request.QuantityForBorrow > 0 ? request.QuantityForBorrow : 0)
                         + (request.QuantityForSale > 0 ? request.QuantityForSale : 0);

            if (totalAdd != restockRequest.QuantityRequested)
                throw new InvalidOperationException($"Moraš unijeti tačno {restockRequest.QuantityRequested} knjiga.");

            if (bb == null)
            {
                bb = new BookBranch
                {
                    BranchId = branchId,
                    BookId = request.BookId,
                    SupportsBorrowing = request.QuantityForBorrow > 0,
                    QuantityForBorrow = request.QuantityForBorrow,
                    QuantityForSale = request.QuantityForSale
                };
                _context.BookBranches.Add(bb);
            }
            else
            {
                bb.QuantityForBorrow += request.QuantityForBorrow;
                bb.QuantityForSale += request.QuantityForSale;
                if (request.QuantityForBorrow > 0)
                    bb.SupportsBorrowing = true;
            }

            restockRequest.Status = RestockRequestStatus.Recieved;
            await _context.SaveChangesAsync();
            if (bb.QuantityForBorrow > 0 && bb.QuantityForSale > 0)
            {
                var subs = await _context.NotificationRequests
                    .Where(n => n.BookId == request.BookId && n.BranchId == branchId)
                    .Include(n => n.User)
                    .ToListAsync();

                foreach (var sub in subs)
                {
                    //var payload = sub.User?.Email ?? "";
                    //if (!string.IsNullOrEmpty(payload))
                    //{
                    //    var body = Encoding.UTF8.GetBytes(payload);

                    //    _channel.BasicPublish(
                    //        exchange: "",
                    //        routingKey: _queueName,
                    //        basicProperties: null,
                    //        body: body
                    //    );
                    //    Console.WriteLine($"[RabbitMQ] Published payload='{payload}' to queue='{_queueName}'");
                    //}
                    _context.NotificationRequests.Remove(sub);
                }

                await _context.SaveChangesAsync();
            }
        }

        public async Task<List<BranchInventoryResponse>> GetAvailabilityByBookIdAsync(int bookId, bool sandbox)
        {
            var query = _context.BookBranches
                .Include(bb => bb.Book).ThenInclude(b => b.Genre)
                .Include(bb => bb.Book).ThenInclude(b => b.Language)
                .Include(bb => bb.Branch).ThenInclude(b => b.City)
                .Where(bb => bb.BookId == bookId && (bb.QuantityForSale > 0 || bb.QuantityForBorrow > 0));
            if (sandbox)
            {
                query = query
                    .IgnoreQueryFilters()
                    .Where(bb => bb.IsSandbox);
            }

            var result = await query
                .OrderBy(bb => bb.BranchId)
                .Select(bb => new BranchInventoryResponse
                {
                    BookId = bb.BookId,
                    BranchId = bb.BranchId,
                    BranchName = bb.Branch.Name ?? "Nepoznata filiala",
                    BranchAdress = (bb.Branch.Address ?? "Nepoznata adresa") +
                                   ((bb.Branch.City != null && bb.Branch.City.Name != null) ? ", " + bb.Branch.City.Name : ""),
                    Title = bb.Book.Title ?? "Nepoznat naslov",
                    Author = bb.Book.Author ?? "Nepoznat autor",
                    GenreName = bb.Book.Genre != null ? bb.Book.Genre.Name ?? "Nepoznat žanr" : "Nepoznat žanr",
                    LanguageName = bb.Book.Language != null ? bb.Book.Language.Name ?? "Nepoznat jezik" : "Nepoznat jezik",
                    Price = bb.Book.Price,
                    PhotoEndpoint = $"/api/books/{bb.BookId}/photo",
                    SupportsBorrowing = bb.SupportsBorrowing,
                    QuantityForBorrow = bb.QuantityForBorrow,
                    QuantityForSale = bb.QuantityForSale
                })
                .ToListAsync();

            return result;
        }


        public async Task<bool> DeleteAsync(int branchId, int bookId)
        {
            var bb = await _context.BookBranches
                .FirstOrDefaultAsync(x => x.BranchId == branchId && x.BookId == bookId);
            if (bb == null) return false;

            _context.BookBranches.Remove(bb);
            await _context.SaveChangesAsync();
            return true;
        }

        protected BranchInventoryResponse MapToDto(BookBranch bb)
        {
            if (bb == null)
                throw new ArgumentNullException(nameof(bb), "BookBranch cannot be null");

            return new BranchInventoryResponse
            {
                BookId = bb.BookId,
                BranchId = bb.BranchId,
                BranchName = bb.Branch?.Name ?? "Nepoznata filiala",
                BranchAdress = (bb.Branch?.Address ?? "Nepoznata adresa") +
                              ((bb.Branch?.City?.Name != null) ? ", " + bb.Branch.City.Name : ""),
                Title = bb.Book?.Title ?? "Nepoznat naslov",
                Author = bb.Book?.Author ?? "Nepoznat autor",
                GenreName = bb.Book?.Genre?.Name ?? "Nepoznat žanr",
                LanguageName = bb.Book?.Language?.Name ?? "Nepoznat jezik",
                Price = bb.Book?.Price ?? 0,
                PhotoEndpoint = $"/books/{bb.BookId}/photo",
                SupportsBorrowing = bb.SupportsBorrowing,
                QuantityForBorrow = bb.QuantityForBorrow,
                QuantityForSale = bb.QuantityForSale
            };
        }
    }
}