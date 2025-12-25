using Knjigoteka.Model;
using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.ML;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.ML.Data;
namespace Knjigoteka.Services.Services
{
    public class BookService
        : BaseCRUDService<BookResponse, BookSearchObject, BookInsert, BookUpdate, Book>, IBookService
    {
        protected readonly DatabaseContext _context;
        private static readonly object _lock = new();
        private static MLContext? _ml;
        private static ITransformer? _model;
        private static DataViewSchema? _modelSchema;
        private static DateTime _modelBuiltAt = DateTime.MinValue;
        public BookService(DatabaseContext context) : base(context) { _context = context; }

        protected override IQueryable<Book> ApplyFilter(IQueryable<Book> query, BookSearchObject? search)
        {

            if (search == null) return query;
            if (search.Sandbox)
            {
                query = _context.Books
                    .IgnoreQueryFilters()
                    .Where(b => b.IsSandbox);
            }
            if (!string.IsNullOrWhiteSpace(search.FTS))
            {
                query = query.Where(b => b.Title.Contains(search.FTS) ||
                    b.Author.Contains(search.FTS));
            }
            if (search.GenreId.HasValue)
            {
                query = query.Where(b => b.GenreId == search.GenreId.Value);
            }

            if (search.LanguageId.HasValue)
            {
                query = query.Where(b => b.LanguageId == search.LanguageId.Value);
            }

            return query.OrderBy(a=>a.Title);
        }
        public override async Task<BookResponse> GetById(int id)
        {
            var entity = await _context.Books
                .Include(b => b.Genre)
                .Include(b => b.Language)
                .Include(b => b.BookBranches)
                .Include(b => b.Reviews)
                .FirstOrDefaultAsync(b => b.Id == id)
                ?? throw new KeyNotFoundException("Book not found.");

            return MapToDto(entity);
        }
        protected override IQueryable<Book> AddInclude(IQueryable<Book> query)
        {
            return query
                .Include(b => b.Genre)
                .Include(b => b.Language)
                .Include(b => b.BookBranches)
                .Include(b => b.Reviews);
        }
        public override async Task<BookResponse> Update(int id, BookUpdate request)
        {
            var entity = await _context.Books
                .Include(b => b.Genre)
                .Include(b => b.Language)
                .FirstOrDefaultAsync(b => b.Id == id)
                ?? throw new Exception("Book not found.");

            MapToEntity(request, entity);
            await _context.SaveChangesAsync();
            await _context.Entry(entity).Reference(b => b.Genre).LoadAsync();
            await _context.Entry(entity).Reference(b => b.Language).LoadAsync();
            return MapToDto(entity);
        }
        public override async Task<BookResponse> Insert(BookInsert request)
        {
            var entity = MapToEntity(request);
            await _context.Set<Book>().AddAsync(entity);
            await _context.SaveChangesAsync();

            var reloaded = await _context.Books
                .Include(b => b.Genre)
                .Include(b => b.Language)
                .FirstOrDefaultAsync(b => b.Id == entity.Id);

            return MapToDto(reloaded!);
        }

        protected override BookResponse MapToDto(Book e)
        {
            var avg = (e.Reviews != null && e.Reviews.Any())
            ? (double?)Math.Round(e.Reviews.Average(r => r.Rating), 2)
            : null;
            return new BookResponse
            {
                Id = e.Id,
                Title = e.Title,
                Author = e.Author,
                GenreId = e.GenreId,
                GenreName = e.Genre.Name,
                LanguageId = e.LanguageId,
                LanguageName = e.Language.Name,
                ISBN = e.ISBN,
                Year = e.Year,
                CentralStock = e.CentralStock,
                CalculatedTotalQuantity = (e.BookBranches?.Sum(bb => bb.QuantityForBorrow + bb.QuantityForSale) ?? 0) + e.CentralStock,
                ShortDescription = e.ShortDescription,
                Price = e.Price,
                HasImage = e.BookImage != null && e.BookImage.Length > 0,
                PhotoEndpoint = $"/books/{e.Id}/photo",
                AverageRating = avg,
                ReviewsCount = e.Reviews.Count(),
            };
        }

        protected override Book MapToEntity(BookInsert request)
        {
            return new Book
            {
                Title = request.Title,
                Author = request.Author,
                GenreId = request.GenreId,
                LanguageId = request.LanguageId,
                ISBN = request.ISBN,
                Year = request.Year,
                CentralStock = request.CentralStock,
                ShortDescription = request.ShortDescription,
                Price = request.Price,
                BookImage = request.BookImage
            };
        }
        protected override void MapToEntity(BookUpdate request, Book entity)
        {
            entity.Title = request.Title;
            entity.Author = request.Author;
            entity.GenreId = request.GenreId;
            entity.LanguageId = request.LanguageId;
            entity.ISBN = request.ISBN;
            entity.Year = request.Year;
            entity.CentralStock = request.CentralStock;
            entity.ShortDescription = request.ShortDescription;
            entity.Price = request.Price;
            if (request.BookImage != null && request.BookImage.Length > 0)
                entity.BookImage = request.BookImage;
        }
        public async Task<List<BookResponse>> RecommendAsync(int bookId, int take = 3)
        {

            var orders = await _context.Orders
                .Include(o => o.OrderItems)
                .ToListAsync();

            var pairs = new List<CoPurchaseInput>();
            foreach (var o in orders)
            {
                var items = o.OrderItems
                              .Select(oi => oi.BookId)
                              .Distinct()
                              .ToList();

                if (items.Count <= 1) continue;

                foreach (var a in items)
                {
                    foreach (var b in items)
                    {
                        if (a == b) continue;
                        pairs.Add(new CoPurchaseInput
                        {
                            ProductId = (uint)a,
                            CoProductId = (uint)b,
                            Label = 1f
                        });
                    }
                }
            }

            if (pairs.Count == 0)
                return new List<BookResponse>();

            EnsureModel(pairs);

            if (_model is null || _ml is null)
                return new List<BookResponse>();
            var candidateArticles = await _context.Books
                .Where(b => b.Id != bookId)
                .Include(b => b.Genre)
                .Include(b => b.Language)
                .Include(b => b.BookBranches)
                .Include(b => b.Reviews)
                .ToListAsync();


            if (candidateArticles.Count == 0)
                return new List<BookResponse>();


            var inputs = candidateArticles.Select(c => new CoPurchaseInput
            {
                ProductId = (uint)bookId,
                CoProductId = (uint)c.Id,
                Label = 0f 
            });

            var inputView = _ml.Data.LoadFromEnumerable(inputs);
            var scored = _model.Transform(inputView);

            var scores = _ml.Data.CreateEnumerable<CoPurchaseScore>(scored, reuseRowObject: false).ToList();

            var ranked = candidateArticles.Zip(scores, (art, sc) => new { art, sc.Score })
                                          .OrderByDescending(x => x.Score)
                                          .Take(Math.Max(1, take))
                                          .Select(x => x.art)
                                          .ToList();

            return ranked.Select(MapToDto).ToList();
        }

        private void EnsureModel(List<CoPurchaseInput> pairs)
        {
            var needRebuild = (_model == null) || (DateTime.UtcNow - _modelBuiltAt > TimeSpan.FromMinutes(30));
            if (!needRebuild) return;

            lock (_lock)
            {
                if (_model != null && (DateTime.UtcNow - _modelBuiltAt <= TimeSpan.FromMinutes(30)))
                    return;

                _ml ??= new MLContext(seed: 42);
                var data = _ml.Data.LoadFromEnumerable(pairs);

                var pipeline =
                    _ml.Transforms.Conversion.MapValueToKey("ProductIdEncoded", nameof(CoPurchaseInput.ProductId))
                      .Append(_ml.Transforms.Conversion.MapValueToKey("CoProductIdEncoded", nameof(CoPurchaseInput.CoProductId)))
                      .Append(_ml.Recommendation().Trainers.MatrixFactorization(new Microsoft.ML.Trainers.MatrixFactorizationTrainer.Options
                      {
                          MatrixColumnIndexColumnName = "ProductIdEncoded",
                          MatrixRowIndexColumnName = "CoProductIdEncoded",
                          LabelColumnName = nameof(CoPurchaseInput.Label),
                          LossFunction = Microsoft.ML.Trainers.MatrixFactorizationTrainer.LossFunctionType.SquareLossOneClass,
                          Alpha = 0.01,
                          Lambda = 0.025,
                          NumberOfIterations = 100,
                          C = 0.00001
                      }));

                _model = pipeline.Fit(data);
                _modelSchema = data.Schema;
                _modelBuiltAt = DateTime.UtcNow;
            }
        }




        private sealed class CoPurchaseInput
        {
            public uint ProductId { get; set; }
            public uint CoProductId { get; set; }
            public float Label { get; set; }
        }

        private sealed class CoPurchaseScore
        {
            public float Score { get; set; }
        }

    }
}
