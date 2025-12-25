namespace Knjigoteka.Model.SearchObjects
{
    public class BaseSearchObject
    {
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 1000;
        public bool IncludeTotalCount { get; set; } = true;
    }
}
