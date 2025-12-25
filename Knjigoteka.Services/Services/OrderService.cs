using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.Services.Utilities;
using Microsoft.EntityFrameworkCore;
using System.Data;

namespace Knjigoteka.Services.Services
{
    public class OrderService : IOrderService
    {
        private readonly DatabaseContext _context;
        private readonly IUserContext _user;

        public OrderService(DatabaseContext context, IUserContext user)
        {
            _context = context;
            _user = user;
        }

        public async Task<OrderResponse> CheckoutAsync(OrderCreate dto)
        {
            var userId = _user.UserId;

            var cart = await _context.CartItems
                .Include(ci => ci.Book)
                .Where(ci => ci.UserId == userId)
                .ToListAsync();

            if (cart.Count == 0)
                throw new InvalidOperationException("Cart is empty.");

            if (cart.Any(ci => ci.Quantity <= 0))
                throw new InvalidOperationException("Invalid quantity in cart.");

            await using var tx = await _context.Database.BeginTransactionAsync(IsolationLevel.Serializable);
            try
            {
                foreach (var ci in cart)
                {
                    var book = await _context.Books.SingleOrDefaultAsync(b => b.Id == ci.BookId);
                    if (book == null)
                        throw new KeyNotFoundException($"Book (Id={ci.BookId}) not found.");

                    if (book.CentralStock < ci.Quantity)
                        throw new InvalidOperationException($"Not enough stock for '{book.Title}'. Requested: {ci.Quantity}, available: {book.CentralStock}.");
                }

                var total = cart.Sum(i => i.Book.Price * i.Quantity);

                var order = new Order
                {
                    UserId = userId,
                    OrderDate = DateTime.UtcNow,
                    Status = OrderStatus.Pending,
                    PaymentMethod = dto.PaymentMethod,
                    DeliveryAddress = dto.DeliveryAddress,
                    TotalAmount = total
                };

                _context.Orders.Add(order);
                await _context.SaveChangesAsync();

                var orderItems = new List<OrderItem>();
                foreach (var ci in cart)
                {
                    var book = await _context.Books.SingleAsync(b => b.Id == ci.BookId);
                    book.CentralStock -= ci.Quantity;
                    if (book.CentralStock < 0)
                        throw new InvalidOperationException($"Stock underflow for '{book.Title}'.");

                    orderItems.Add(new OrderItem
                    {
                        OrderId = order.Id,
                        BookId = ci.BookId,
                        Quantity = ci.Quantity,
                        UnitPrice = ci.Book.Price
                    });
                }

                _context.OrderItems.AddRange(orderItems);

                _context.CartItems.RemoveRange(cart);

                await _context.SaveChangesAsync();

                await tx.CommitAsync();

                return MapOrder(order);
            }
            catch
            {
                await tx.RollbackAsync();
                throw;
            }
        }

        private static OrderResponse MapOrder(Order o) => new()
        {
            Id = o.Id,
            CreatedAt = o.OrderDate,
            UserName = o.User != null ? o.User.FirstName + " " + o.User.LastName : "",
            Status = o.Status,
            PaymentMethod = o.PaymentMethod,
            TotalAmount = o.TotalAmount,
            Items = o.OrderItems.Select(oi => new OrderItemResponse
            {
                BookId = oi.BookId,
                Title = oi.Book.Title,
                Author = oi.Book.Author,
                Quantity = oi.Quantity,
                UnitPrice = oi.UnitPrice,
                PhotoEndpoint = $"/api/books/{oi.BookId}/photo",
            }).ToList()
        };

        public async Task<List<OrderResponse>> GetMyOrdersAsync()
        {
            var orders = await _context.Orders
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Book)
                .Include(u => u.User)
                .Where(o => o.UserId == _user.UserId)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync();

            return orders.Select(MapOrder).ToList();
        }

        public async Task<List<OrderResponse>> GetAllAsync()
        {
            var orders = await _context.Orders
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Book)
                .Include(u => u.User)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync();

            return orders.Select(MapOrder).ToList();
        }
        public async Task<bool> ApproveAsync(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null)
                return false;
            if (order.Status != OrderStatus.Pending)
                throw new InvalidOperationException("Order već procesiran.");

            order.Status = OrderStatus.Approved;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> RejectAsync(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null)
                return false;
            if (order.Status != OrderStatus.Pending)
                throw new InvalidOperationException("Order već procesiran.");

            order.Status = OrderStatus.Rejected;
            await _context.SaveChangesAsync();
            return true;
        }

    }
}
