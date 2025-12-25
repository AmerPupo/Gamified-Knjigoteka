import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:knjigoteka_mobile/providers/base_provider.dart';
import '../models/book.dart';
import '../providers/auth_provider.dart';

class BookProvider extends BaseProvider<Book> {
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://10.0.2.2:7295/api",
  );

  BookProvider() : super("Books");

  @override
  Book fromJson(dynamic data) => Book.fromJson(data);

  Future<List<Book>> getBooks({
    String? fts = '',
    int? genreId,
    int? languageId,
  }) async {
    final params = <String, dynamic>{};
    if (fts != null && fts.isNotEmpty) params['FTS'] = fts;
    if (genreId != null) params['GenreId'] = genreId.toString();
    if (languageId != null) params['LanguageId'] = languageId.toString();
    return getAll(params: params);
  }

  Future<Book> getBook(int id) async {
    return getById(id);
  }

  Future<List<Book>> getRecommendedBooks(int bookId, {int take = 3}) async {
    String url = '$_baseUrl/Books/$bookId/recommend?take=$take';
    final res = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (AuthProvider.token != null && AuthProvider.token!.isNotEmpty)
          'Authorization': 'Bearer ${AuthProvider.token}',
      },
    );
    if (res.statusCode != 200) throw Exception("Greška: ${res.body}");
    final data = jsonDecode(res.body);
    final List items = data is List ? data : (data['items'] ?? []);
    return items.map((e) => Book.fromJson(e)).toList();
  }
}
