using Knjigoteka.Model.Responses;

namespace Knjigoteka.Services.Interfaces
{
    public interface ICRUDService<T, TSearch, TInsert, TUpdate> : IService<T, TSearch>
        where T : class
        where TSearch : class
        where TInsert : class
        where TUpdate : class
    {
        Task<T> Insert(TInsert request);
        Task<T> Update(int id, TUpdate request);
        Task<bool> Delete(int id);
    }
}
