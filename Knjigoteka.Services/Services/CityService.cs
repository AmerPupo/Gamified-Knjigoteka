using Knjigoteka.Model.Entities;
using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Knjigoteka.Services.Services
{
    public class CityService
        : BaseCRUDService<CityResponse, CitySearchObject, CityInsert, CityUpdate, City>, ICityService
    {
        public CityService(DatabaseContext context) : base(context) { }

        protected override IQueryable<City> ApplyFilter(IQueryable<City> query, CitySearchObject? search)
        {
            if( search == null ) return query;

            if(!string.IsNullOrWhiteSpace(search.FTS))
                query = query.Where(c => c.Name.Contains(search.FTS));

            return query;
        }

        protected override CityResponse MapToDto(City entity)
        {
            return new CityResponse
            {
                Id = entity.Id,
                Name = entity.Name
            };
        }

        protected override City MapToEntity(CityInsert request)
        {
            return new City
            {
                Name = request.Name
            };
        }
        protected override void MapToEntity(CityUpdate request, City entity)
        {
            entity.Name = request.Name;
        }
    }
}
