using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Interfaces
{
    public interface INotificationRequestService
    {
        Task<NotificationRequestResponse> CreateAsync(NotificationRequestCreate dto);
        Task<List<NotificationRequestResponse>> GetMyRequestsAsync();
        Task<List<NotificationRequestResponse>> GetAllAsync();
        Task<bool> DeleteAsync(int id);
    }

}
