using RabbitMQ.Client;
using Knjigoteka.Services.Interfaces;

namespace Knjigoteka.Services.Services
{
    public class RabbitMQConnectionManager : IRabbitMQService, IDisposable
    {
        private readonly ConnectionFactory _factory;
        private IConnection? _connection;
        private bool _disposed = false;
        private readonly RabbitMQ.Client.IModel channel;

        public RabbitMQConnectionManager()
        {
            var host = Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? "localhost";
            var username = Environment.GetEnvironmentVariable("RABBITMQ_USERNAME") ?? "guest";
            var password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD") ?? "guest";
            var port = int.TryParse(Environment.GetEnvironmentVariable("RABBITMQ_PORT"), out var p) ? p : 5672;

            _factory = new ConnectionFactory()
            {
                HostName = host,
                UserName = username,
                Password = password,
                Port = port,
                AutomaticRecoveryEnabled = true,           // auto reconnect
                NetworkRecoveryInterval = TimeSpan.FromSeconds(5),
                TopologyRecoveryEnabled = true
            };

            // retry logika
            const int maxRetries = 20;
            for (int i = 1; i <= maxRetries; i++)
            {
                try
                {
                    _connection = _factory.CreateConnection();
                    Console.WriteLine("RabbitMQ connection established.");
                    break;
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"RabbitMQ not ready, attempt {i}/{maxRetries}: {ex.Message}");
                    if (i == maxRetries)
                        throw; // nakon max pokušaja digni exception
                    Thread.Sleep(3000); // čekaj 3 sekunde prije sljedećeg pokušaja
                }
            }

            channel = _connection!.CreateModel();
            var queueName = Environment.GetEnvironmentVariable("RABBITMQ_QUEUE") ?? "mailqueue";

            channel.QueueDeclare(
                queue: queueName,
                durable: false,
                exclusive: false,
                autoDelete: false,
                arguments: null);
        }

        public RabbitMQ.Client.IModel GetChannel() => channel;


        public void Dispose()
        {
            if (_disposed)
                return;

            _connection?.Dispose();
            _disposed = true;
        }
    }
}