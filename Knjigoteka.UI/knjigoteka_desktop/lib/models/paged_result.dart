class PagedResult<T> {
  final List<T> items;
  final int totalCount;

  PagedResult({required this.items, required this.totalCount});
}
