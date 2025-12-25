using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Interfaces
{
    public interface ICartService
    {
        Task<CartResponse> GetAsync();
        Task<CartResponse> UpsertAsync(CartItemUpsert dto);
        Task<bool> RemoveAsync(int bookId);
        Task ClearAsync();
    }
}
