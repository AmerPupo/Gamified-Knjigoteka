using Knjigoteka.Services.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Utilities
{
    public class ReservationExpirationBackgroundService : BackgroundService
    {
        private readonly IServiceProvider _services;
        private readonly ILogger<ReservationExpirationBackgroundService> _logger;
        private readonly TimeSpan _interval = TimeSpan.FromMinutes(5); // prilagodi

        public ReservationExpirationBackgroundService(IServiceProvider services, ILogger<ReservationExpirationBackgroundService> logger)
        {
            _services = services;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Reservation expiration background service started.");
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    using var scope = _services.CreateScope();
                    var service = scope.ServiceProvider.GetRequiredService<IReservationService>();
                    var processed = await service.ExpirePendingReservationsAsync();
                    if (processed > 0)
                        _logger.LogInformation("Expired {Count} reservations.", processed);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in reservation expiration background job.");
                }

                await Task.Delay(_interval, stoppingToken);
            }
            _logger.LogInformation("Reservation expiration background service stopping.");
        }
    }

}
