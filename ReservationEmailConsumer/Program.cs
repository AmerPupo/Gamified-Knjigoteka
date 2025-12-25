using Microsoft.Extensions.Configuration;
using DotNetEnv;
class Program
{
    static void Main(string[] args)
    {
        Env.Load();
        var configuration = new ConfigurationBuilder()
           .AddEnvironmentVariables()
           .Build();



        var emailService = new EmailService(configuration);

        var reservationEmailConsumer = new ReservationEmailConsumer(configuration, emailService);
        reservationEmailConsumer.Start();             // pokreće slušanje
        Console.WriteLine("Reservation Email Consumer started");
        Thread.Sleep(Timeout.Infinite);



    }
}