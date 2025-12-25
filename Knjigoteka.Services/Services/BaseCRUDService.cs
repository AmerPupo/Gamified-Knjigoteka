using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Interfaces;
using Knjigoteka.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace Knjigoteka.Services.Services
{
    public class BaseCRUDService<T, TSearch, TInsert, TUpdate, TEntity>
        : BaseService<T, TSearch, TEntity>, ICRUDService<T, TSearch, TInsert, TUpdate>
        where T : class
        where TSearch : BaseSearchObject
        where TInsert : class
        where TUpdate : class
        where TEntity : class, new()
    {
        public BaseCRUDService(DatabaseContext context) : base(context) { }

        public virtual async Task<T> Insert(TInsert request)
        {
            var entity = MapToEntity(request);
            _context.Set<TEntity>().Add(entity);
            await _context.SaveChangesAsync();
            return MapToDto(entity);
        }

        public virtual async Task<T> Update(int id, TUpdate request)
        {
            var entity = await _context.Set<TEntity>().FindAsync(id);

            if (entity == null)
                throw new Exception("Entity not found.");

            MapToEntity(request, entity);
            await _context.SaveChangesAsync();
            return MapToDto(entity);
        }

        public virtual async Task<bool> Delete(int id)
        {
            var entity = await _context.Set<TEntity>().FindAsync(id);

            if (entity == null)
                return false;

            _context.Set<TEntity>().Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }

        protected virtual TEntity MapToEntity(TInsert request)
        {
            throw new NotImplementedException("Override MapToEntity in your service.");
        }

        protected virtual void MapToEntity(TUpdate request, TEntity entity)
        {
            throw new NotImplementedException("Override MapToEntity in your service.");
        }
    }
}
