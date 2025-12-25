using Knjigoteka.Model;
using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.Services.Services;
using Knjigoteka.Services.Utilities;
using Microsoft.EntityFrameworkCore;

public class ReviewService
    : BaseCRUDService<ReviewResponse, ReviewSearchObject, ReviewInsert, ReviewUpdate, Review>, IReviewService
{
    private readonly DatabaseContext _context;
    private readonly IUserContext _user;

    public ReviewService(DatabaseContext context, IUserContext user)
        : base(context)
    {
        _context = context;
        _user = user;
    }

    protected override IQueryable<Review> AddInclude(IQueryable<Review> query)
    {
        return query.Include(r => r.Book).Include(r => r.User);
    }

    protected override IQueryable<Review> ApplyFilter(IQueryable<Review> query, ReviewSearchObject? search)
    {
        if (search == null) return query;
        if (search.BookId.HasValue)
            query = query.Where(r => r.BookId == search.BookId.Value);
        if (search.UserId.HasValue)
            query = query.Where(r => r.UserId == search.UserId.Value);
        if (search.MinRating.HasValue)
            query = query.Where(r => r.Rating >= search.MinRating.Value);
        if (search.MaxRating.HasValue)
            query = query.Where(r => r.Rating <= search.MaxRating.Value);
        return query;
    }
    public override async Task<ReviewResponse> Update(int id, ReviewUpdate req)
    {
        var entity = await _context.Reviews.Include(r => r.User).FirstOrDefaultAsync(r => r.Id == id)
            ?? throw new KeyNotFoundException("Review not found.");

        if (entity.UserId != _user.UserId)
            throw new UnauthorizedAccessException("Only review owner can update this review.");

        MapToEntity(req, entity);
        await _context.SaveChangesAsync();
        return MapToDto(entity);
    }

    public override async Task<bool> Delete(int id)
    {
        var entity = await _context.Reviews.FindAsync(id);
        if (entity == null)
            return false;

        if (entity.UserId != _user.UserId)
            throw new UnauthorizedAccessException("Only review owner can delete this review.");

        _context.Reviews.Remove(entity);
        await _context.SaveChangesAsync();
        return true;
    }

    protected override ReviewResponse MapToDto(Review r)
    {
        return new ReviewResponse
        {
            Id = r.Id,
            BookId = r.BookId,
            BookTitle = r.Book?.Title ?? "",
            UserId = r.UserId,
            UserFullName = r.User != null ? $"{r.User.FirstName} {r.User.LastName}" : "",
            Rating = r.Rating,
            CreatedAt = r.CreatedAt
        };
    }

    protected override Review MapToEntity(ReviewInsert req)
    {
        return new Review
        {
            BookId = req.BookId,
            UserId = _user.UserId,
            Rating = req.Rating,
            CreatedAt = DateTime.Now
        };
    }

    protected override void MapToEntity(ReviewUpdate req, Review entity)
    {
        entity.Rating = req.Rating;
    }

    public async Task<List<ReviewResponse>> GetByBookAsync(int bookId)
    {
        var items = await _context.Reviews
            .Include(r => r.User)
            .Include(r => r.Book)
            .Where(r => r.BookId == bookId)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        return items.Select(MapToDto).ToList();
    }

    public async Task<List<ReviewResponse>> GetByUserAsync(int userId)
    {
        var items = await _context.Reviews
            .Include(r => r.Book)
            .Include(r => r.User)
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        return items.Select(MapToDto).ToList();
    }
}
