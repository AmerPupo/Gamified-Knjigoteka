using Knjigoteka.Model.Entities;
using Knjigoteka.Services.Database;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace Knjigoteka.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class SeedController : ControllerBase
    {
        private readonly DatabaseContext _db;

        private const int RES_STATUS_REJECTED = 0;
        private const int RES_STATUS_CONFIRMED = 1;
        private const int RES_STATUS_PENDING = 2;
        private readonly string _webRoot;
        private readonly string _contentRoot;
       public SeedController(DatabaseContext db, IWebHostEnvironment env)
        {
            _db = db;
            _webRoot = string.IsNullOrWhiteSpace(env.WebRootPath)
                ? Path.Combine(env.ContentRootPath, "wwwroot")
                : env.WebRootPath;
            _contentRoot = env.ContentRootPath;
        }

        [HttpPost("init")]
        public async Task<IActionResult> Init()
        {
            if (!await _db.Roles.AnyAsync())
            {
                await _db.Roles.AddRangeAsync(new[]
                {
                    new Role { Name = "Admin" },
                    new Role { Name = "Employee" },
                    new Role { Name = "User" }
                });
                await _db.SaveChangesAsync();
            }

            if (!await _db.Cities.AnyAsync())
            {
                await _db.Cities.AddRangeAsync(new[]
                {
                    new City { Name = "Tuzla" },
                    new City { Name = "Sarajevo" },
                    new City { Name = "Mostar" }
                });
                await _db.SaveChangesAsync();
            }

            if (!await _db.Branches.AnyAsync())
            {
                var cityTuzla = await _db.Cities.FirstAsync();
                var citySa = await _db.Cities.OrderBy(x => x.Id).Skip(1).FirstAsync();
                await _db.Branches.AddRangeAsync(new[]
                {
                    new Branch { Name = "Centralna", Address = "Zlatnih ljiljana 1", CityId = cityTuzla.Id, PhoneNumber = "035-123-456" },
                    new Branch { Name = "Sarajevska", Address = "Titova 22", CityId = citySa.Id, PhoneNumber = "033-987-654" }
                });
                await _db.SaveChangesAsync();
            }

            var hasher = new PasswordHasher<User>();
            if (!await _db.Users.AnyAsync())
            {
                await _db.Users.AddRangeAsync(new[]
                {
                    MakeUser(1, "admin@knjigoteka.local", "Admin", "Glavni", "Admin123!", hasher),
                    MakeUser(2, "radnik@knjigoteka.local", "Emir", "Radnik", "Radnik123!", hasher),
                    MakeUser(3, "pupo@knjigoteka.local", "Pupo", "Korisnik", "Pupo123!", hasher),
                    MakeUser(3, "ana@knjigoteka.local", "Ana", "Knjiga", "Ana123!", hasher)
                });
                await _db.SaveChangesAsync();
            }

            var branchCentral = await _db.Branches.FirstAsync();
            var employeeUser = await _db.Users.FirstOrDefaultAsync(u => u.Email == "radnik@knjigoteka.local");
            if (employeeUser != null && !await _db.Employees.AnyAsync(e => e.UserId == employeeUser.Id))
            {
                await _db.Employees.AddAsync(new Employee
                {
                    UserId = employeeUser.Id,
                    EmploymentDate = DateTime.UtcNow.AddYears(-1),
                    BranchId = branchCentral.Id,
                    IsActive = true
                });
                await _db.SaveChangesAsync();
            }

            if (!await _db.Genres.AnyAsync())
            {
                await _db.Genres.AddRangeAsync(new[]
                {
                    new Genre { Name = "Roman" },
                    new Genre { Name = "Naučna fantastika" },
                    new Genre { Name = "Drama" },
                    new Genre { Name = "Psihologija" }
                });
                await _db.SaveChangesAsync();
            }
            if (!await _db.Languages.AnyAsync())
            {
                await _db.Languages.AddRangeAsync(new[]
                {
                    new Language { Name = "Bosanski" },
                    new Language { Name = "Engleski" },
                    new Language { Name = "Njemački" }
                });
                await _db.SaveChangesAsync();
            }

            var genreRoman = await _db.Genres.FirstAsync();
            var langBos = await _db.Languages.FirstAsync();
            if (!await _db.Books.AnyAsync())
            {
                await _db.Books.AddRangeAsync(new[]
                {
                    new Book {
                        Title = "Derviš i smrt",
                        Author = "Meša Selimović",
                        GenreId = genreRoman.Id,
                        LanguageId = langBos.Id,
                        ISBN = "9789958002341",
                        Year = 1966,
                        Price = 21,
                        CentralStock = 14,
                        ShortDescription = "Kultni roman, filozofska drama.",
                        BookImage = LoadImageOrNull("dervis.jpg")
                    },
                    new Book {
                        Title = "Na Drini ćuprija",
                        Author = "Ivo Andrić",
                        GenreId = genreRoman.Id,
                        LanguageId = langBos.Id,
                        ISBN = "9789958001234",
                        Year = 1945,
                        Price = 19,
                        CentralStock = 10,
                        ShortDescription = "Ep o jednom mostu i jednom gradu.",
                        BookImage = LoadImageOrNull("cuprija.jpg")
                    },
                    new Book {
                        Title = "Prokleta avlija",
                        Author = "Ivo Andrić",
                        GenreId = genreRoman.Id,
                        LanguageId = langBos.Id,
                        ISBN = "9789958004321",
                        Year = 1954,
                        Price = 18,
                        CentralStock = 7,
                        ShortDescription = "Roman o zatvoru i krivici.",
                        BookImage = LoadImageOrNull("avlija.jpg")
                    },
                    new Book {
                        Title = "The Great Gatsby",
                        Author = "F. Scott Fitzgerald",
                        GenreId = genreRoman.Id,
                        LanguageId = langBos.Id,
                        ISBN = "9780743273565",
                        Year = 1925,
                        Price = 25,
                        CentralStock = 12,
                        ShortDescription = "Kultni roman o bogatstvu i propasti u doba džez ere.",
                        BookImage = LoadImageOrNull("gatsby.jpg")
                    },
                    new Book {
                        Title = "1984",
                        Author = "George Orwell",
                        GenreId = genreRoman.Id,
                        LanguageId = langBos.Id,
                        ISBN = "9780451524935",
                        Year = 1949,
                        Price = 20,
                        CentralStock = 16,
                        ShortDescription = "Distopijski roman o totalitarnoj kontroli i gubitku slobode.",
                        BookImage = LoadImageOrNull("1984.jpg")
                    }
                });
                await _db.SaveChangesAsync();
            }

            var branch1 = await _db.Branches.FirstAsync();
            var branch2 = await _db.Branches.OrderBy(x => x.Id).Skip(1).FirstAsync();
            var knjige = await _db.Books.ToListAsync();
            if (!await _db.BookBranches.AnyAsync())
            {
                await _db.BookBranches.AddRangeAsync(new[]
                {
                    new BookBranch { BranchId = branch1.Id, BookId = knjige[0].Id, QuantityForSale = 5, QuantityForBorrow = 4, SupportsBorrowing = true },
                    new BookBranch { BranchId = branch1.Id, BookId = knjige[1].Id, QuantityForSale = 2, QuantityForBorrow = 3, SupportsBorrowing = true },
                    new BookBranch { BranchId = branch2.Id, BookId = knjige[2].Id, QuantityForSale = 6, QuantityForBorrow = 1, SupportsBorrowing = true }
                });
                await _db.SaveChangesAsync();
            }

            var userPupo = await _db.Users.FirstAsync(u => u.FirstName.ToLower() == "pupo");
            var branchInv = await _db.BookBranches.FirstAsync();
            // --- SEED PAR REZERVACIJA ---
            if (!await _db.Reservations.AnyAsync())
            {
                var users = await _db.Users.OrderBy(x => x.Id).ToListAsync();
                var knjigeList = await _db.Books.ToListAsync();
                var reservations = new List<Reservation>
    {
        new Reservation
        {
            UserId = users[2].Id, // Pupo
            BookId = knjigeList[0].Id, // Derviš i smrt
            BranchId = branch1.Id,
            ReservedAt = DateTime.UtcNow.AddDays(-2),
            Status = ReservationStatus.Pending
        },
        new Reservation
        {
            UserId = users[3].Id, // Ana
            BookId = knjigeList[1].Id, // Na Drini ćuprija
            BranchId = branch1.Id,
            ReservedAt = DateTime.UtcNow.AddDays(-1),
            Status = ReservationStatus.Claimed,
            ClaimedAt = DateTime.UtcNow.AddHours(-22)
        },
    };
                await _db.Reservations.AddRangeAsync(reservations);
                await _db.SaveChangesAsync();
            }

            // --- SEED PAR POSUDBI ---
            if (!await _db.Borrowings.AnyAsync())
            {
                var users = await _db.Users.OrderBy(x => x.Id).ToListAsync();
                var knjigeList = await _db.Books.ToListAsync();
                var reservationAna = await _db.Reservations.FirstOrDefaultAsync(r => r.Status == ReservationStatus.Claimed);

                var borrowings = new List<Borrowing>
    {
        new Borrowing
        {
            UserId = users[2].Id, // Pupo
            BookId = knjigeList[0].Id, // Derviš i smrt
            BranchId = branch1.Id,
            BorrowedAt = DateTime.UtcNow.AddDays(-5),
            DueDate = DateTime.UtcNow.AddDays(10)
        },
        new Borrowing
        {
            UserId = users[3].Id, // Ana
            BookId = knjigeList[1].Id, // Na Drini ćuprija
            BranchId = branch1.Id,
            BorrowedAt = DateTime.UtcNow.AddDays(-7),
            DueDate = DateTime.UtcNow.AddDays(-1),
            ReturnedAt = DateTime.UtcNow.AddDays(-2), // Vraćeno prije roka
            ReservationId = reservationAna?.Id // povezano s rezervacijom
        },
        new Borrowing
        {
            UserId = users[2].Id, // Pupo
            BookId = knjigeList[2].Id, // Prokleta avlija
            BranchId = branch2.Id,
            BorrowedAt = DateTime.UtcNow.AddDays(-10),
            DueDate = DateTime.UtcNow.AddDays(-2),
            ReturnedAt = null // nije vraćeno, kasni
        }
    };
                await _db.Borrowings.AddRangeAsync(borrowings);
                await _db.SaveChangesAsync();
            }


            if (!await _db.Orders.AnyAsync())
            {
                await _db.Orders.AddAsync(new Order
                {
                    UserId = userPupo.Id,
                    OrderDate = DateTime.UtcNow.AddDays(-2),
                    DeliveryAddress = "Moja adresa 123, Tuzla",
                    PaymentMethod = "gotovina",
                    TotalAmount = 41.40m
                });
                await _db.SaveChangesAsync();
            }

            if (!await _db.Penalties.AnyAsync())
            {
                await _db.Penalties.AddAsync(new Penalty
                {
                    UserId = userPupo.Id,
                    Reason = "Kasni sa vraćanjem knjige",
                    CreatedAt = DateTime.UtcNow.AddDays(-2)
                });
                await _db.SaveChangesAsync();
            }

            if (!await _db.Reviews.AnyAsync())
            {
                await _db.Reviews.AddAsync(new Review
                {
                    UserId = userPupo.Id,
                    BookId = knjige[0].Id,
                    Rating = 5,
                    CreatedAt = DateTime.UtcNow
                });
                await _db.SaveChangesAsync();
            }
            // --- SEED PAR RESTOCK REQUESTOVA ---
            if (!await _db.RestockRequests.AnyAsync())
            {
                var knjigeList = await _db.Books.ToListAsync();
                var employee = await _db.Employees.FirstAsync();

                var restocks = new List<RestockRequest>
    {
        new RestockRequest
        {
            BookId = knjigeList[0].Id, // Derviš i smrt
            BranchId = branch1.Id,
            EmployeeId = employee.Id,
            RequestDate = DateTime.UtcNow.AddDays(-8),
            QuantityRequested = 5,
            Status = RestockRequestStatus.Pending
        },
        new RestockRequest
        {
            BookId = knjigeList[1].Id, // Na Drini ćuprija
            BranchId = branch2.Id,
            EmployeeId = employee.Id,
            RequestDate = DateTime.UtcNow.AddDays(-5),
            QuantityRequested = 3,
            Status = RestockRequestStatus.Approved
        },
        new RestockRequest
        {
            BookId = knjigeList[2].Id, // Prokleta avlija
            BranchId = branch1.Id,
            EmployeeId = employee.Id,
            RequestDate = DateTime.UtcNow.AddDays(-2),
            QuantityRequested = 4,
            Status = RestockRequestStatus.Recieved
        },
        new RestockRequest
        {
            BookId = knjigeList[3].Id, // The Great Gatsby
            BranchId = branch2.Id,
            EmployeeId = employee.Id,
            RequestDate = DateTime.UtcNow.AddDays(-12),
            QuantityRequested = 2,
            Status = RestockRequestStatus.Rejected
        }
    };

                await _db.RestockRequests.AddRangeAsync(restocks);
                await _db.SaveChangesAsync();
            }
            //await SeedSandboxData();
            //await SeedSandboxData();
            await SeedRealBooksFromSandbox();
            return Ok("Knjigoteka SEED complete!");
        }
        private async Task SeedSandboxData()
        {
            // 0) Ako nema gradova, nema smisla nastavljati
            var cities = await _db.Cities.OrderBy(c => c.Id).ToListAsync();
            if (!cities.Any())
                return;

            // 1) SANDBOX POSLOVNICE (cilj: barem 3)
            // ⬇️ bitno: ignoriramo globalni filter, jer tražimo baš sandbox poslovnice
            var sandboxBranches = await _db.Branches
                .IgnoreQueryFilters()
                .Where(b => b.IsSandbox)
                .OrderBy(b => b.Id)
                .ToListAsync();

            if (sandboxBranches.Count < 3)
            {
                // kreiraj onoliko koliko fali do 3
                while (sandboxBranches.Count < 3)
                {
                    var index = sandboxBranches.Count; // 0,1,2...
                    var city = cities[Math.Min(index, cities.Count - 1)];

                    var branch = new Branch
                    {
                        Name = $"Sandbox poslovnica {sandboxBranches.Count + 1}",
                        Address = $"Sandbox ulica {sandboxBranches.Count + 1}",
                        CityId = city.Id,
                        PhoneNumber = $"000-000-00{sandboxBranches.Count + 1}",
                        IsSandbox = true
                    };

                    _db.Branches.Add(branch);
                    sandboxBranches.Add(branch);
                }

                await _db.SaveChangesAsync();
            }

            var sandboxBranchMain = sandboxBranches[0];
            var sandboxBranch2 = sandboxBranches[1];
            var sandboxBranch3 = sandboxBranches[2];

            // 2) SANDBOX KNJIGE – KOPIJE SVIH POSTOJEĆIH KNJIGA
            // ⬇️ opet ignoriramo filter, jer provjeravamo da li sandbox knjige već postoje
            if (!await _db.Books
                    .IgnoreQueryFilters()
                    .AnyAsync(b => b.IsSandbox))
            {
                // sve "prave" knjige (IsSandbox == false)
                // ovdje može i bez IgnoreQueryFilters, ali da bude eksplicitno:
                var originalBooks = await _db.Books
                    .IgnoreQueryFilters()
                    .Where(b => !b.IsSandbox)
                    .ToListAsync();

                var sandboxBooksToInsert = new List<Book>();

                foreach (var ob in originalBooks)
                {
                    var clone = new Book
                    {
                        Title = ob.Title,
                        Author = ob.Author,
                        GenreId = ob.GenreId,
                        LanguageId = ob.LanguageId,
                        // da ne pravi konflikt ako imaš unique index na ISBN
                        ISBN = ob.ISBN + "-SB",
                        Year = ob.Year,
                        Price = ob.Price,
                        // mora imati nešto na centralnom skladištu
                        CentralStock = ob.CentralStock > 0 ? ob.CentralStock : 20,
                        ShortDescription = ob.ShortDescription,
                        BookImage = ob.BookImage,
                        BookImageContentType = ob.BookImageContentType,
                        IsSandbox = true
                    };

                    sandboxBooksToInsert.Add(clone);
                }

                _db.Books.AddRange(sandboxBooksToInsert);
                await _db.SaveChangesAsync();
            }

            // sve sandbox knjige (duplikati)
            var sandboxBooksAll = await _db.Books
                .IgnoreQueryFilters()
                .Where(b => b.IsSandbox)
                .OrderBy(b => b.Id)
                .ToListAsync();

            // neke posebne reference za tutorijale
            var sbCuprija = sandboxBooksAll.FirstOrDefault(b => b.Title.Contains("Na Drini"))
                            ?? sandboxBooksAll.First();
            var sbDervis = sandboxBooksAll.FirstOrDefault(b => b.Title.Contains("Derviš"))
                           ?? sandboxBooksAll.Skip(1).FirstOrDefault()
                           ?? sandboxBooksAll.First();
            var sb1984 = sandboxBooksAll.FirstOrDefault(b => b.Title.Contains("1984"))
                         ?? sandboxBooksAll.Skip(2).FirstOrDefault()
                         ?? sandboxBooksAll.First();
            var extraExists = await _db.Books
    .IgnoreQueryFilters()
    .AnyAsync(b => b.IsSandbox && b.ISBN.StartsWith("SB-EX"));

            if (!extraExists)
            {
                var defGenre = await _db.Genres.FirstAsync();
                var defLang = await _db.Languages.FirstAsync();

                var extraBooks = new List<Book>
    {
        new Book { Title = "Zločin i kazna", Author = "Fjodor Dostojevski", GenreId = defGenre.Id, LanguageId = defLang.Id, ISBN = "SB-EX-0001", Year = 1866, Price = 20, CentralStock = 12, ShortDescription = "Klasik ruske književnosti.", IsSandbox = true, BookImage = LoadImageOrNull("zik.jpg") },
        new Book { Title = "Braća Karamazovi", Author = "F. M. Dostojevski", GenreId = defGenre.Id, LanguageId = defLang.Id, ISBN = "SB-EX-0002", Year = 1880, Price = 24, CentralStock = 10, ShortDescription = "Psihološki roman o moralu i vjeri.", IsSandbox = true, BookImage = LoadImageOrNull("karamazovi.jpg") },
        new Book { Title = "Ubiti pticu rugalicu", Author = "Harper Lee", GenreId = defGenre.Id, LanguageId = defLang.Id, ISBN = "SB-EX-0003", Year = 1960, Price = 18, CentralStock = 15, ShortDescription = "Američki klasik o pravdi.", IsSandbox = true, BookImage = LoadImageOrNull("ptica.jpg") },
        new Book { Title = "Lovac u žitu", Author = "J. D. Salinger", GenreId = defGenre.Id, LanguageId = defLang.Id, ISBN = "SB-EX-0004", Year = 1951, Price = 17, CentralStock = 14, ShortDescription = "Roman o odrastanju.", IsSandbox = true, BookImage = LoadImageOrNull("lovac.jpg") },
        new Book { Title = "Sto godina samoće", Author = "Gabriel García Márquez", GenreId = defGenre.Id, LanguageId = defLang.Id, ISBN = "SB-EX-0005", Year = 1967, Price = 22, CentralStock = 11, ShortDescription = "Magijski realizam.", IsSandbox = true, BookImage = LoadImageOrNull("sto_godina.jpg") },

        new Book { Title = "Gospodar prstenova: Družina prstena", Author = "J. R. R. Tolkien", GenreId = defGenre.Id, LanguageId = defLang.Id, ISBN = "SB-EX-0006", Year = 1954, Price = 30, CentralStock = 20, ShortDescription = "Početak trilogije.", IsSandbox = true, BookImage = LoadImageOrNull("druzina.jpg") },
        new Book { Title = "Gospodar prstenova: Dvije kule", Author = "J. R. R. Tolkien", GenreId = defGenre.Id, LanguageId = defLang.Id, ISBN = "SB-EX-0007", Year = 1954, Price = 30, CentralStock = 20, ShortDescription = "Drugi dio trilogije.", IsSandbox = true, BookImage = LoadImageOrNull("dvije_kule.jpg") },
        new Book { Title = "Gospodar prstenova: Povratak kralja", Author = "J. R. R. Tolkien", GenreId = defGenre.Id, LanguageId = defLang.Id, ISBN = "SB-EX-0008", Year = 1955, Price = 30, CentralStock = 20, ShortDescription = "Završetak trilogije.", IsSandbox = true, BookImage = LoadImageOrNull("povratak.jpg") },

        new Book { Title = "Harry Potter i Kamen mudraca", Author = "J. K. Rowling", GenreId = defGenre.Id, LanguageId = defLang.Id, ISBN = "SB-EX-0009", Year = 1997, Price = 17, CentralStock = 25, ShortDescription = "Prva HP knjiga.", IsSandbox = true, BookImage = LoadImageOrNull("hp1.jpg") },
        new Book { Title = "Harry Potter i Odaja tajni", Author = "J. K. Rowling", GenreId = defGenre.Id, LanguageId = defLang.Id, ISBN = "SB-EX-0010", Year = 1998, Price = 17, CentralStock = 25, ShortDescription = "Druga HP knjiga.", IsSandbox = true, BookImage = LoadImageOrNull("hp2.jpg") },
        new Book { Title = "Harry Potter i Zatočenik Azkabana", Author = "J. K. Rowling", GenreId = defGenre.Id, LanguageId = defLang.Id, ISBN = "SB-EX-0011", Year = 1999, Price = 17, CentralStock = 25, ShortDescription = "Treća HP knjiga.", IsSandbox = true, BookImage = LoadImageOrNull("hp3.jpg") },

        new Book { Title = "Rat i mir", Author = "Lav Tolstoj", GenreId = defGenre.Id, LanguageId = defLang.Id, ISBN = "SB-EX-0012", Year = 1869, Price = 28, CentralStock = 9, ShortDescription = "Epski roman Rusije.", IsSandbox = true, BookImage = LoadImageOrNull("rat.jpg") },
        new Book { Title = "Ana Karenjina", Author = "Lav Tolstoj", GenreId = defGenre.Id, LanguageId = defLang.Id, ISBN = "SB-EX-0013", Year = 1878, Price = 23, CentralStock = 13, ShortDescription = "Ljubavna tragedija.", IsSandbox = true, BookImage = LoadImageOrNull("ana.jpg") },
        new Book { Title = "Alhemičar", Author = "Paulo Coelho", GenreId = defGenre.Id, LanguageId = defLang.Id, ISBN = "SB-EX-0014", Year = 1988, Price = 15, CentralStock = 30, ShortDescription = "Duhovna potraga.", IsSandbox = true, BookImage = LoadImageOrNull("alhemicar.jpg") },
        new Book { Title = "Mali princ", Author = "Antoine de Saint-Exupéry", GenreId = defGenre.Id, LanguageId = defLang.Id, ISBN = "SB-EX-0015", Year = 1943, Price = 12, CentralStock = 18, ShortDescription = "Bezvremenska priča.", IsSandbox = true, BookImage = LoadImageOrNull("princ.jpg") }
    };

                _db.Books.AddRange(extraBooks);
                await _db.SaveChangesAsync();

                sandboxBooksAll = await _db.Books
                    .IgnoreQueryFilters()
                    .Where(b => b.IsSandbox)
                    .OrderBy(b => b.Id)
                    .ToListAsync();
            }
            // 3) SANDBOX BOOKBRANCH – RASPODJELA U VIŠE POSLOVNICA
            if (!await _db.BookBranches
                    .IgnoreQueryFilters()
                    .AnyAsync(bb => bb.IsSandbox))
            {
                var bbList = new List<BookBranch>();

                foreach (var book in sandboxBooksAll)
                {
                    // Glavna sandbox poslovnica – uvijek ima nešto za prodaju i posudbu
                    bbList.Add(new BookBranch
                    {
                        BranchId = sandboxBranchMain.Id,
                        BookId = book.Id,
                        QuantityForSale = 5,
                        QuantityForBorrow = 2,
                        SupportsBorrowing = true,
                        IsSandbox = true
                    });

                    // Druga sandbox poslovnica – više za prodaju, bez posudbe
                    bbList.Add(new BookBranch
                    {
                        BranchId = sandboxBranch2.Id,
                        BookId = book.Id,
                        QuantityForSale = 3,
                        QuantityForBorrow = 0,
                        SupportsBorrowing = false,
                        IsSandbox = true
                    });

                    // Treća sandbox poslovnica – samo za posudbu
                    bbList.Add(new BookBranch
                    {
                        BranchId = sandboxBranch3.Id,
                        BookId = book.Id,
                        QuantityForSale = 0,
                        QuantityForBorrow = 3,
                        SupportsBorrowing = true,
                        IsSandbox = true
                    });
                }

                _db.BookBranches.AddRange(bbList);
                await _db.SaveChangesAsync();
            }
            
            var extraBooksbb = await _db.Books
    .IgnoreQueryFilters()
    .Where(b => b.IsSandbox && b.ISBN.StartsWith("SB-EX"))
    .ToListAsync();

            var bbExtra = new List<BookBranch>();
            int ei = 0;

            foreach (var book in extraBooksbb)
            {
                bool skipMain = ei % 2 == 0;

                if (!skipMain)
                {
                    bbExtra.Add(new BookBranch
                    {
                        BranchId = sandboxBranchMain.Id,
                        BookId = book.Id,
                        QuantityForSale = 4,
                        QuantityForBorrow = 2,
                        SupportsBorrowing = true,
                        IsSandbox = true
                    });
                }

                bbExtra.Add(new BookBranch
                {
                    BranchId = sandboxBranch2.Id,
                    BookId = book.Id,
                    QuantityForSale = 3,
                    QuantityForBorrow = 0,
                    SupportsBorrowing = false,
                    IsSandbox = true
                });

                if (ei % 3 == 0)
                {
                    bbExtra.Add(new BookBranch
                    {
                        BranchId = sandboxBranch3.Id,
                        BookId = book.Id,
                        QuantityForSale = 0,
                        QuantityForBorrow = 3,
                        SupportsBorrowing = true,
                        IsSandbox = true
                    });
                }

                ei++;
            }

            _db.BookBranches.AddRange(bbExtra);
            await _db.SaveChangesAsync();

            // 4) SANDBOX REZERVACIJE
            if (!await _db.Reservations
                    .IgnoreQueryFilters()
                    .AnyAsync(r => r.IsSandbox))
            {
                var users = await _db.Users
                    .OrderBy(u => u.Id)
                    .ToListAsync();

                var userPupo = users.FirstOrDefault(u => u.Email == "pupo@knjigoteka.local")
                               ?? users.ElementAtOrDefault(2)
                               ?? users.First();
                var userAna = users.FirstOrDefault(u => u.Email == "ana@knjigoteka.local")
                              ?? users.ElementAtOrDefault(3)
                              ?? users.First();

                var reservations = new List<Reservation>
        {
            new Reservation
            {
                UserId = userPupo.Id,
                BookId = sbCuprija.Id,
                BranchId = sandboxBranchMain.Id,
                ReservedAt = DateTime.UtcNow.AddDays(-2),
                Status = ReservationStatus.Pending,
                IsSandbox = true
            },
            new Reservation
            {
                UserId = userAna.Id,
                BookId = sbDervis.Id,
                BranchId = sandboxBranchMain.Id,
                ReservedAt = DateTime.UtcNow.AddDays(-5),
                Status = ReservationStatus.Claimed,
                ClaimedAt = DateTime.UtcNow.AddDays(-4),
                IsSandbox = true
            }
        };

                _db.Reservations.AddRange(reservations);
                await _db.SaveChangesAsync();
            }

            // 5) SANDBOX POSUDBE
            if (!await _db.Borrowings
                    .IgnoreQueryFilters()
                    .AnyAsync(b => b.IsSandbox))
            {
                var users = await _db.Users
                    .OrderBy(u => u.Id)
                    .ToListAsync();

                var userPupo = users.FirstOrDefault(u => u.Email == "pupo@knjigoteka.local")
                               ?? users.ElementAtOrDefault(2)
                               ?? users.First();
                var userAna = users.FirstOrDefault(u => u.Email == "ana@knjigoteka.local")
                              ?? users.ElementAtOrDefault(3)
                              ?? users.First();

                var claimedSandboxRes = await _db.Reservations
                    .IgnoreQueryFilters()
                    .FirstOrDefaultAsync(r => r.IsSandbox && r.Status == ReservationStatus.Claimed);

                var borrowings = new List<Borrowing>
        {
            new Borrowing
            {
                UserId = userPupo.Id,
                BookId = sbCuprija.Id,
                BranchId = sandboxBranchMain.Id,
                BorrowedAt = DateTime.UtcNow.AddDays(-7),
                DueDate = DateTime.UtcNow.AddDays(7),
                ReturnedAt = null,
                IsSandbox = true
            },
            new Borrowing
            {
                UserId = userAna.Id,
                BookId = sbDervis.Id,
                BranchId = sandboxBranchMain.Id,
                BorrowedAt = DateTime.UtcNow.AddDays(-10),
                DueDate = DateTime.UtcNow.AddDays(-1),
                ReturnedAt = DateTime.UtcNow.AddDays(-2),
                ReservationId = claimedSandboxRes?.Id,
                IsSandbox = true
            }
        };

                _db.Borrowings.AddRange(borrowings);
                await _db.SaveChangesAsync();
            }

            // 6) SANDBOX RESTOCK REQUESTOVI
            if (!await _db.RestockRequests
                    .IgnoreQueryFilters()
                    .AnyAsync(r => r.IsSandbox))
            {
                var employee = await _db.Employees
                    .Include(e => e.User)
                    .FirstAsync();

                var restocks = new List<RestockRequest>
        {
            new RestockRequest
            {
                BookId = sbCuprija.Id,
                BranchId = sandboxBranchMain.Id,
                EmployeeId = employee.Id,
                RequestDate = DateTime.UtcNow.AddDays(-3),
                QuantityRequested = 5,
                Status = RestockRequestStatus.Approved,
                IsSandbox = true
            }
        };

                _db.RestockRequests.AddRange(restocks);
                await _db.SaveChangesAsync();
            }
        }


        private async Task SeedRealBooksFromSandbox()
        {
            // 0) Učitaj sve sandbox knjige (one ostaju sandbox, samo ih čitamo)
            var sandboxBooks = await _db.Books
                .IgnoreQueryFilters()
                .Where(b => b.IsSandbox)
                .ToListAsync();

            if (!sandboxBooks.Any())
                return;

            // 1) Postojeće realne knjige
            var realBooks = await _db.Books
                .IgnoreQueryFilters()
                .Where(b => !b.IsSandbox)
                .ToListAsync();

            // 2) Realne poslovnice (bez sandbox)
            var realBranches = await _db.Branches
                .IgnoreQueryFilters()
                .Where(b => !b.IsSandbox)
                .ToListAsync();


            if (!realBranches.Any())
                return;

            var newRealBooks = new List<Book>();

            foreach (var sb in sandboxBooks)
            {
                // preskoči ako već postoji realna knjiga sa istim Title + Author
                var alreadyExists = realBooks.Any(b =>
                    !b.IsSandbox &&
                    b.Title == sb.Title &&
                    b.Author == sb.Author);

                if (alreadyExists)
                    continue;

                // riješi ISBN da bude unikatan u realnim knjigama
                var newIsbn = sb.ISBN;

                if (string.IsNullOrWhiteSpace(newIsbn))
                {
                    // generišemo “fake” ISBN da zadovolji unique constraint
                    newIsbn = $"R-{Guid.NewGuid():N}".Substring(0, 13);
                }
                else if (realBooks.Any(b => !b.IsSandbox && b.ISBN == newIsbn))
                {
                    // ako već postoji ista vrijednost u realnim knjigama, dodaj sufiks
                    newIsbn = newIsbn + "-R";
                }

                var clone = new Book
                {
                    Title = sb.Title,
                    Author = sb.Author,
                    GenreId = sb.GenreId,
                    LanguageId = sb.LanguageId,
                    ISBN = newIsbn,
                    Year = sb.Year,
                    Price = sb.Price,
                    CentralStock = sb.CentralStock > 0 ? sb.CentralStock : 10,
                    ShortDescription = sb.ShortDescription,
                    BookImage = sb.BookImage,
                    BookImageContentType = sb.BookImageContentType,
                    IsSandbox = false // OVDE JE FORA – sad je “prava” knjiga
                };

                newRealBooks.Add(clone);
                realBooks.Add(clone); // da i naredne iteracije vide novu knjigu
            }

            if (!newRealBooks.Any())
                return;

            // 3) Sačuvaj nove realne knjige
            _db.Books.AddRange(newRealBooks);
            await _db.SaveChangesAsync();

            // 4) Dodaj ih u realne poslovnice
            var mainBranch = realBranches.FirstOrDefault(b => b.Id == 1)
                             ?? realBranches.OrderBy(b => b.Id).First();

            // druga realna (ako postoji), ali manje bitna
            var secondBranch = realBranches
                .Where(b => b.Id != mainBranch.Id)
                .OrderBy(b => b.Id)
                .FirstOrDefault();

            var newBookBranches = new List<BookBranch>();

            foreach (var book in newRealBooks)
            {
                // glavna poslovnica – prodaja + posudba
                newBookBranches.Add(new BookBranch
                {
                    BranchId = mainBranch.Id,
                    BookId = book.Id,
                    QuantityForSale = 8,
                    QuantityForBorrow = 5,
                    SupportsBorrowing = true,
                    IsSandbox = false
                });

                // druga poslovnica – samo prodaja (ako postoji)
                if (secondBranch != null)
                {
                    newBookBranches.Add(new BookBranch
                    {
                        BranchId = secondBranch.Id,
                        BookId = book.Id,
                        QuantityForSale = 3,
                        QuantityForBorrow = 0,
                        SupportsBorrowing = false,
                        IsSandbox = false
                    });
                }
            }

            _db.BookBranches.AddRange(newBookBranches);
            await _db.SaveChangesAsync();
        }

        private static User MakeUser(int roleId, string email, string first, string last, string pass, PasswordHasher<User> hasher)
        {
            var u = new User
            {
                Email = email,
                FirstName = first,
                LastName = last,
                RoleId = roleId
            };
            u.PasswordHash = hasher.HashPassword(u, pass);
            return u;
        }

        private byte[]? LoadImageOrNull(string fileName)
        {
            var path = Path.Combine(_webRoot, "pics", fileName);
            if (System.IO.File.Exists(path))
                return System.IO.File.ReadAllBytes(path);
            var path2 = Path.Combine(_contentRoot, "wwwroot", "pics", fileName);
            if (System.IO.File.Exists(path2))
                return System.IO.File.ReadAllBytes(path2);
            return null;
        }
    }
}
