using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.Services.Utilities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Knjigoteka.Services.Services
{
    public class ReservationService
        : BaseCRUDService<ReservationResponse, ReservationSearchObject, ReservationRequest, ReservationRequest, Reservation>, IReservationService
    {
        private readonly IUserContext _userContext;
        private readonly DatabaseContext _context;
        private readonly IPenaltyService _penaltyService;
        private readonly IUserService _userService;
        private readonly ILogger<ReservationService> _logger;
        public ReservationService(
               DatabaseContext context,
               IUserContext userContext,
               IPenaltyService penaltyService,
               IUserService userService,
               ILogger<ReservationService> logger)
               : base(context)
        {
            _context = context;
            _userContext = userContext;
            _penaltyService = penaltyService;
            _userService = userService;
            _logger = logger;
        }

        protected override IQueryable<Reservation> AddInclude(IQueryable<Reservation> query)
        {
            return query
                .Include(r => r.Book)
                .Include(r => r.Branch)
                .Include(r => r.User);
        }

        protected override IQueryable<Reservation> ApplyFilter(IQueryable<Reservation> query, ReservationSearchObject? search)
        {
            if (search == null) return query;
            if (search.Sandbox)
            {
                query = query
                    .IgnoreQueryFilters()
                    .Where(r => r.IsSandbox);
            }
            if (search.UserId.HasValue)
                query = query.Where(r => r.UserId == search.UserId.Value);

            if(!string.IsNullOrWhiteSpace(search.UserName))
                query = query.Where(r => r.User.FirstName.ToLower().StartsWith(search.UserName.ToLower()) || r.User.LastName.ToLower().StartsWith(search.UserName.ToLower()));

            if (search.BranchId.HasValue)
                query = query.Where(r => r.BranchId == search.BranchId.Value);

            if (!string.IsNullOrWhiteSpace(search.Status))
                query = query.Where(r => r.Status.ToString() == search.Status);

            if (search.ActiveOnly)
                query = query.Where(r =>
                    r.Status == ReservationStatus.Pending || r.Status == ReservationStatus.Claimed);

            query = query
       .OrderBy(r => r.Status == ReservationStatus.Pending ? 0 : 1)
       .ThenByDescending(r => r.ReservedAt);
            return query;
        }

        public override async Task<ReservationResponse> Insert(ReservationRequest request)
        {
            var userId = _userContext.UserId;

            var existing = await _context.Reservations.AnyAsync(r =>
                r.UserId == userId &&
                r.BookId == request.BookId &&
                r.Status == ReservationStatus.Pending);

            if (existing)
                throw new InvalidOperationException("Već imate aktivnu rezervaciju za ovu knjigu.");
            var bookBranch = await _context.BookBranches
            .FirstOrDefaultAsync(bb => bb.BranchId == request.BranchId && bb.BookId == request.BookId);

            if (bookBranch == null || !bookBranch.SupportsBorrowing || bookBranch.QuantityForBorrow <= 0)
                throw new InvalidOperationException("Knjiga nije dostupna za rezervaciju u ovoj poslovnici.");

            bookBranch.QuantityForBorrow -= 1;
            var entity = new Reservation
            {
                BookId = request.BookId,
                BranchId = request.BranchId,
                ReservedAt = DateTime.Now,
                Status = ReservationStatus.Pending,
                UserId = userId
            };

            _context.Reservations.Add(entity);
            await _context.SaveChangesAsync();

            var full = await _context.Reservations
                .Include(r => r.Book)
                .Include(r => r.Branch)
                .Include(r => r.User)
                .FirstAsync(r => r.Id == entity.Id);

            return MapToDto(full);
        }
        public async Task<int> ExpirePendingReservationsAsync()
        {
            var now = DateTime.UtcNow;
            var toExpire = await _context.Reservations
                .Where(r => r.Status == ReservationStatus.Pending && r.ExpiredAt != null && r.ExpiredAt < now)
                .ToListAsync();

            if (!toExpire.Any()) return 0;

            using var tx = await _context.Database.BeginTransactionAsync();
            try
            {
                foreach (var r in toExpire)
                {
                    r.Status = ReservationStatus.Expired;
                    r.ExpiredAt = r.ExpiredAt ?? now;

                    var bookBranch = await _context.BookBranches
                        .FirstOrDefaultAsync(bb => bb.BookId == r.BookId && bb.BranchId == r.BranchId);

                    if (bookBranch != null)
                        bookBranch.QuantityForBorrow += 1;

                    await _penaltyService.AddAsync(r.UserId, "Unclaimed reservation");
                    await _userService.BlockIfExceededPenaltyThreshold(r.UserId);
                }

                await _context.SaveChangesAsync();
                await tx.CommitAsync();

                _logger.LogInformation("Expired {Count} reservations.", toExpire.Count);
                return toExpire.Count;
            }
            catch (Exception ex)
            {
                await tx.RollbackAsync();
                _logger.LogError(ex, "Error while expiring reservations.");
                throw;
            }
        }

        protected override ReservationResponse MapToDto(Reservation entity)
        {
            return new ReservationResponse
            {
                Id = entity.Id,
                UserId = entity.UserId,
                UserName = entity.User.FirstName + " " + entity.User.LastName,
                BookId = entity.BookId,
                BookTitle = entity.Book?.Title ?? "",
                BranchId = entity.BranchId,
                BranchName = entity.Branch?.Name ?? "",
                ReservedAt = entity.ReservedAt,
                ClaimedAt = entity.ClaimedAt,
                ReturnedAt = entity.ReturnedAt,
                ExpiredAt = entity.ExpiredAt,
                Status = entity.Status.ToString()
            };
        }

        protected override Reservation MapToEntity(ReservationRequest request)
        {
            return new Reservation
            {
                BookId = request.BookId,
                BranchId = request.BranchId,
                ReservedAt = DateTime.Now,
                Status = ReservationStatus.Pending,
                UserId = _userContext.UserId
            };
        }

        protected override void MapToEntity(ReservationRequest request, Reservation entity)
        {

        }
    }
}
