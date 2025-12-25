using Knjigoteka.Model.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Interfaces
{
    public interface IPenaltyService
    {
        Task AddAsync(int userId, string reason);
        Task<int> GetPointsAsync(int userId);
        Task<List<Penalty>> GetUserPenaltiesAsync(int userId);
    }

}
