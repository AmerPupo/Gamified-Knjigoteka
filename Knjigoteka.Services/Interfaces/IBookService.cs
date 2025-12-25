using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Interfaces
{
    public interface IBookService
        : ICRUDService<BookResponse, BookSearchObject, BookInsert, BookUpdate>
    {
        Task<List<BookResponse>> RecommendAsync(int bookId, int take = 3);
    }
}
