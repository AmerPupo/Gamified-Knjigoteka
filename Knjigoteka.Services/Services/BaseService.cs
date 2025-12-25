using Knjigoteka.Model.Helpers;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Database;
using Knjigoteka.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Knjigoteka.Services.Services
{
    public class BaseService<T, TSearch, TEntity> : IService<T, TSearch>
        where T : class
        where TSearch : BaseSearchObject
        where TEntity : class
    {
        protected readonly DatabaseContext _context;

        public BaseService(DatabaseContext context)
        {
            _context = context;
        }

        public virtual async Task<PagedResult<T>> Get(TSearch? search = null)
        {
            var query = _context.Set<TEntity>().AsQueryable();
            query = ApplyFilter(query, search);
            query = AddInclude(query);

            var totalCount = search?.IncludeTotalCount == true ? await query.CountAsync() : 0;

            if (search?.Page > 0 && search?.PageSize > 0)
            {
                query = query
                    .Skip((search.Page - 1) * search.PageSize)
                    .Take(search.PageSize);
            }

            var list = await query.ToListAsync();

            return new PagedResult<T>
            {
                Items = list.Select(MapToDto).ToList(),
                TotalCount = totalCount
            };
        }

        public virtual async Task<T> GetById(int id)
        {
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if (entity == null)
                return null;

            return MapToDto(entity!);
        }

        protected virtual IQueryable<TEntity> ApplyFilter(IQueryable<TEntity> query, TSearch? search)
        {
            return query;
        }
        protected virtual IQueryable<TEntity> AddInclude(IQueryable<TEntity> query)
        {
            return query;
        }
        protected virtual T MapToDto(TEntity entity)
        {
            throw new NotImplementedException("You must override MapToDto in your service.");
        }
    }
}
