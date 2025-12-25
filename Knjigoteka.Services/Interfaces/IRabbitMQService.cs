using Microsoft.EntityFrameworkCore.ChangeTracking.Internal;
using RabbitMQ.Client;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Services
{
    public interface IRabbitMQService
    {
        public IModel GetChannel();
    }
}