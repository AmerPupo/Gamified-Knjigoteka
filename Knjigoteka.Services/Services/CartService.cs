using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.Services.Utilities;
using Microsoft.EntityFrameworkCore;

namespace Knjigoteka.Services.Services
{
    public class CartService : ICartService
    {
        private readonly DatabaseContext _db;
        private readonly IUserContext _user;

        public CartService(DatabaseContext db, IUserContext user)
        {
            _db = db;
            _user = user;
        }

        public async Task<CartResponse> GetAsync()
        {
            var items = await _db.CartItems
                .Include(ci => ci.Book)
                .Where(ci => ci.UserId == _user.UserId)
                .OrderByDescending(ci => ci.AddedAt)
                .ToListAsync();

            return new CartResponse
            {
                Items = items.Select(ci => new CartItemResponse
                {
                    BookId = ci.BookId,
                    Title = ci.Book.Title,
                    Author = ci.Book.Author,
                    UnitPrice = ci.Book.Price,
                    Quantity = ci.Quantity,
                    PhotoEndpoint = $"/books/{ci.BookId}/photo",
                }).ToList()
            };
        }

        public async Task<CartResponse> UpsertAsync(CartItemUpsert dto)
        {
            if (dto.Quantity < 0)
                throw new ArgumentException("Quantity must be >= 0.");

            // Ensure the book exists
            var book = await _db.Books.FindAsync(dto.BookId)
                       ?? throw new KeyNotFoundException("Book not found.");

            var item = await _db.CartItems
                .FirstOrDefaultAsync(ci => ci.UserId == _user.UserId && ci.BookId == dto.BookId);

            if (dto.Quantity == 0)
            {
                if (item != null)
                {
                    _db.CartItems.Remove(item);
                    await _db.SaveChangesAsync();
                }
                return await GetAsync();
            }

            if (item == null)
            {
                item = new CartItem
                {
                    UserId = _user.UserId,
                    BookId = dto.BookId,
                    Quantity = dto.Quantity,
                    AddedAt = DateTime.UtcNow
                };
                _db.CartItems.Add(item);
            }
            else
            {
                item.Quantity = dto.Quantity;
            }

            await _db.SaveChangesAsync();
            return await GetAsync();
        }

        public async Task<bool> RemoveAsync(int bookId)
        {
            var item = await _db.CartItems
                .FirstOrDefaultAsync(ci => ci.UserId == _user.UserId && ci.BookId == bookId);
            if (item == null) return false;

            _db.CartItems.Remove(item);
            await _db.SaveChangesAsync();
            return true;
        }

        public async Task ClearAsync()
        {
            var items = _db.CartItems.Where(ci => ci.UserId == _user.UserId);
            _db.CartItems.RemoveRange(items);
            await _db.SaveChangesAsync();
        }
    }
}
