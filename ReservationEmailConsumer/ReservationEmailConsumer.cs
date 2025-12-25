using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System;
using System.Text;

public class ReservationEmailConsumer
{
    private readonly IModel _channel;
    private readonly EmailService _emailService;
    private readonly string _queueName;

    public ReservationEmailConsumer(IConfiguration configuration, EmailService emailService)
    {
        _emailService = emailService;

        // Čitaj sve iz IConfiguration
        var host = configuration["RABBITMQ_HOST"] ?? "localhost";
        var user = configuration["RABBITMQ_USERNAME"] ?? "guest";
        var pass = configuration["RABBITMQ_PASSWORD"] ?? "guest";
        var port = int.Parse(configuration["RABBITMQ_PORT"] ?? "5672");
        _queueName = configuration["RABBITMQ_QUEUE"] ?? throw new InvalidOperationException("RABBITMQ_QUEUE nije definiran");

        // Postavi konekciju
        var factory = new ConnectionFactory
        {
            HostName = host,
            UserName = user,
            Password = pass,
            Port = port,
            DispatchConsumersAsync = false
        };
        var connection = factory.CreateConnection();
        _channel = connection.CreateModel();

        // Deklariraj queue
        _channel.QueueDeclare(
            queue: _queueName,
            durable: false,
            exclusive: false,
            autoDelete: false,
            arguments: null
        );
    }

    public void Start()
    {
        var consumer = new EventingBasicConsumer(_channel);
        consumer.Received += (model, ea) =>
        {
            var email = Encoding.UTF8.GetString(ea.Body.ToArray());
            Console.WriteLine($"[x] Received email to notify: {email}");

            if (string.IsNullOrWhiteSpace(email))
                return;

            var subject = "Obavijest: Knjiga je dostupna";
            var bodyText = "Knjiga je upravo dopunjena i sada je dostupna za kupovinu ili posudbu.";

            try
            {
                _emailService.SendEmail(email, subject, bodyText);
                Console.WriteLine($"[v] Poslan mejl na {email}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[!] Greška pri slanju mejla na {email}: {ex.Message}");
            }
        };

        _channel.BasicConsume(
            queue: _queueName,
            autoAck: true,
            consumer: consumer
        );

        Console.WriteLine($"[>] Listening on queue '{_queueName}'...");
    }
}