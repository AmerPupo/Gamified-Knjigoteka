using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.Services.Services;
using Knjigoteka.Services.Utilities;
using Knjigoteka.WebAPI.Controllers;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Stripe;
using System.Text;

var builder = WebApplication.CreateBuilder(args);
var contentRoot = builder.Environment.ContentRootPath;

var candidates = new[]
{
    Path.Combine(contentRoot, ".env"),
    Path.GetFullPath(Path.Combine(contentRoot, "..", ".env")),
    Path.GetFullPath(Path.Combine(contentRoot, "..", "..", ".env")),
};

var envFile = candidates.FirstOrDefault(System.IO.File.Exists);
if (envFile != null)
{
    DotNetEnv.Env.Load(envFile); // učita u process env
}


builder.Configuration
       .SetBasePath(Directory.GetCurrentDirectory())
       .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
       .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", optional: true)
       .AddEnvironmentVariables();  // .env varijable su sada u OS env
builder.Services.AddControllers();

builder.Services.AddDbContext<DatabaseContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped<IBookService,BookService>();
builder.Services.AddScoped<IGenreService, GenreService>();
builder.Services.AddScoped<ILanguageService, LanguageService>();
builder.Services.AddScoped<IBranchService, BranchService>();
builder.Services.AddScoped<IBranchInventoryService, BranchInventoryService>();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IUserContext,UserContext>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<ICartService, CartService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<IReservationService, ReservationService>();
builder.Services.AddScoped<IPenaltyService, PenaltyService>();
builder.Services.AddScoped<IRestockRequestService, RestockRequestService>();
builder.Services.AddScoped<INotificationRequestService, NotificationRequestService>();
builder.Services.AddScoped<IBorrowingService, BorrowingService>();
builder.Services.AddScoped<IEmployeeService, EmployeeService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<ISaleService, SaleService>();
builder.Services.AddScoped<IOnboardingService, OnboardingService>();
builder.Services.AddSingleton<IRabbitMQService, RabbitMQConnectionManager>();
var stripeSecret =
    builder.Configuration["Stripe:SecretKey"]
    ?? Environment.GetEnvironmentVariable("Stripe__SecretKey")
    ?? throw new InvalidOperationException("Missing Stripe:SecretKey");

StripeConfiguration.ApiKey = stripeSecret;
builder.Services.AddScoped<StripeService>();


builder.Services.AddHostedService<ReservationExpirationBackgroundService>();

var jwtSettings = builder.Configuration.GetSection("Jwt");
var key = Encoding.UTF8.GetBytes(jwtSettings["Key"]!);
builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.RequireHttpsMetadata = false;
        options.SaveToken = true;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,

            ValidIssuer = jwtSettings["Issuer"],
            ValidAudience = jwtSettings["Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(key),

            ClockSkew = TimeSpan.Zero
        };
        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = ctx =>
            {
                Console.WriteLine($"[Auth] Validation failed: {ctx.Exception.Message}");
                return Task.CompletedTask;
            },
            OnTokenValidated = ctx =>
            {
                Console.WriteLine($"[Auth] Token validated for user: {ctx.Principal.Identity.Name}");
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Knjigoteka API", Version = "v1" });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter your token."
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id   = "Bearer"
                }
            },
            new string[] {}
        }
    });
});
builder.Services.AddScoped<IUserService, UserService>();

var app = builder.Build();

try
{
    using var scope = app.Services.CreateScope();
    var context = scope.ServiceProvider.GetRequiredService<DatabaseContext>();
    var env = scope.ServiceProvider.GetRequiredService<IWebHostEnvironment>();

    Console.WriteLine("Applying EF Core migrations (if any)...");
    try
    {
        await context.Database.MigrateAsync();
    }
    catch (SqlException ex) when (ex.Number == 1801) // Database already exists
    {
        // Ignorišemo – DB već postoji
        Console.WriteLine("Database already exists. Continuing without creating.");
    }

    // Idempotentni seed
    if (!await context.Users.AnyAsync())
    {
        Console.WriteLine("Database is empty. Starting data seeding...");
        var seeder = new SeedController(context, env);
        await seeder.Init();
        Console.WriteLine("Data seeding completed successfully.");
    }
    else
    {
        Console.WriteLine("Database already contains data. Skipping seeding.");
    }
}
catch (Exception ex)
{
    Console.WriteLine($"Startup DB step failed (non-fatal): {ex.Message}");

}
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}


app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

app.Run();
