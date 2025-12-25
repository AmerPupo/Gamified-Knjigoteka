using Knjigoteka.Model.Entities;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Services
{
    public class PenaltyService : IPenaltyService
    {
        private readonly DatabaseContext _context;

        public PenaltyService(DatabaseContext context)
        {
            _context = context;
        }

        public async Task AddAsync(int userId, string reason)
        {
            var penalty = new Penalty
            {
                UserId = userId,
                Reason = reason
            };

            _context.Penalties.Add(penalty);
            await _context.SaveChangesAsync();
        }

        public async Task<int> GetPointsAsync(int userId)
        {
            return await _context.Penalties.CountAsync(p => p.UserId == userId);
        }

        public async Task<List<Penalty>> GetUserPenaltiesAsync(int userId)
        {
            return await _context.Penalties
                .Where(p => p.UserId == userId)
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();
        }
    }

}
