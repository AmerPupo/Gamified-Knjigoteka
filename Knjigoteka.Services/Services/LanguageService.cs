using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Knjigoteka.Services.Services
{
    public class LanguageService
        : BaseCRUDService<LanguageResponse, LanguageSearchObject, LanguageInsert, LanguageUpdate, Language>,
          ILanguageService
    {
        public LanguageService(DatabaseContext context) : base(context) { }

        protected override IQueryable<Language> ApplyFilter(IQueryable<Language> query, LanguageSearchObject? search)
        {
            if (search == null) return query;

            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(l =>
                    EF.Functions.Like(l.Name, $"%{search.Name}%"));
            }

            return query;
        }

        protected override LanguageResponse MapToDto(Language entity)
        {
            return new LanguageResponse
            {
                Id = entity.Id,
                Name = entity.Name
            };
        }

        protected override Language MapToEntity(LanguageInsert request)
        {
            return new Language
            {
                Name = request.Name
            };
        }

        protected override void MapToEntity(LanguageUpdate request, Language entity)
        {
            entity.Name = request.Name;
        }
    }
}
