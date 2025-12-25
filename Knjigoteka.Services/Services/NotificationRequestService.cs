using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Services
{
    using Knjigoteka.Model.Entities;
    using Knjigoteka.Model.Requests;
    using Knjigoteka.Model.Responses;
    using Knjigoteka.Services.Database;
    using Knjigoteka.Services.Interfaces;
    using Knjigoteka.Services.Utilities;
    using Microsoft.EntityFrameworkCore;

    public class NotificationRequestService : INotificationRequestService
    {
        private readonly DatabaseContext _context;
        private readonly IUserContext _user;

        public NotificationRequestService(DatabaseContext context, IUserContext user)
        {
            _context = context;
            _user = user;
        }

        public async Task<NotificationRequestResponse> CreateAsync(NotificationRequestCreate dto)
        {
            bool exists = await _context.NotificationRequests.AnyAsync(
                n => n.UserId == _user.UserId && n.BookId == dto.BookId && n.BranchId == dto.BranchId);
            if (exists)
                throw new InvalidOperationException("Već imate kreiran zahtjev za ovu knjigu.");

            var bookBranch = await _context.BookBranches
                .FirstOrDefaultAsync(bb => bb.BookId == dto.BookId && bb.BranchId == dto.BranchId);

            if (bookBranch == null || !bookBranch.SupportsBorrowing)
                throw new InvalidOperationException("This book is not available for borrowing at the selected branch.");

            var req = new NotificationRequest
            {
                UserId = _user.UserId,
                BookId = dto.BookId,
                BranchId = dto.BranchId,
                RequestedAt = DateTime.Now
            };
            _context.NotificationRequests.Add(req);
            await _context.SaveChangesAsync();

            return await MapToResponse(req.Id);
        }

        public async Task<List<NotificationRequestResponse>> GetMyRequestsAsync()
        {
            var requests = await _context.NotificationRequests
                .Where(r => r.UserId == _user.UserId)
                .Include(r => r.Book)
                .Include(r => r.Branch)
                .OrderByDescending(r => r.RequestedAt)
                .ToListAsync();

            return requests.Select(MapToDto).ToList();
        }

        public async Task<List<NotificationRequestResponse>> GetAllAsync()
        {
            var requests = await _context.NotificationRequests
                .Include(r => r.Book)
                .Include(r => r.Branch)
                .OrderByDescending(r => r.RequestedAt)
                .ToListAsync();

            return requests.Select(MapToDto).ToList();
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var req = await _context.NotificationRequests.FindAsync(id);
            if (req == null || req.UserId != _user.UserId)
                return false;

            _context.NotificationRequests.Remove(req);
            await _context.SaveChangesAsync();
            return true;
        }

        private async Task<NotificationRequestResponse> MapToResponse(int id)
        {
            var req = await _context.NotificationRequests
                .Include(r => r.Book)
                .Include(r => r.Branch)
                .FirstAsync(r => r.Id == id);

            return MapToDto(req);
        }

        private NotificationRequestResponse MapToDto(NotificationRequest r) => new()
        {
            Id = r.Id,
            UserId = r.UserId,
            BookId = r.BookId,
            BookTitle = r.Book?.Title ?? "",
            BranchId = r.BranchId,
            BranchName = r.Branch?.Name ?? "",
            RequestedAt = r.RequestedAt
        };
    }

}
