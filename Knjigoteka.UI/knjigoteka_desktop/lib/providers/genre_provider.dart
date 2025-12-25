import '../models/genre.dart';
import 'base_provider.dart';

class GenreProvider extends BaseProvider<Genre> {
  GenreProvider() : super("Genres");

  @override
  Genre fromJson(data) => Genre.fromJson(data);

  Future<List<Genre>> getGenres() async => getAll();
}
