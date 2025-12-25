using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Helpers;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System.Linq;

namespace Knjigoteka.Services.Services
{
    public class GenreService
        : BaseCRUDService<GenreResponse, GenreSearchObject, GenreInsert, GenreUpdate, Genre>, IGenreService
    {
        public GenreService(DatabaseContext context) : base(context) { }

        protected override IQueryable<Genre> ApplyFilter(IQueryable<Genre> query, GenreSearchObject? search)
        {
            if (search == null) return query;

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(g => g.Name.Contains(search.Name));

            return query;
        }
        public override Task<PagedResult<GenreResponse>> Get(GenreSearchObject? search = null)
        {
            return base.Get(search);
        }
        public override Task<GenreResponse> GetById(int id)
        {
            return base.GetById(id);
        }
        protected override GenreResponse MapToDto(Genre entity)
        {
            return new GenreResponse
            {
                Id = entity.Id,
                Name = entity.Name
            };
        }

        protected override Genre MapToEntity(GenreInsert request)
        {
            return new Genre
            {
                Name = request.Name
            };
        }

        protected override void MapToEntity(GenreUpdate request, Genre entity)
        {
            entity.Name = request.Name;
        }
    }
}
