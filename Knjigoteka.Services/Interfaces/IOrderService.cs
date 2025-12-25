using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Interfaces
{
    public interface IOrderService
    {
        Task<OrderResponse> CheckoutAsync(OrderCreate dto);
        Task<List<OrderResponse>> GetMyOrdersAsync();
        Task<List<OrderResponse>> GetAllAsync();
        Task<bool> ApproveAsync(int id);
        Task<bool> RejectAsync(int id);
    }
}
