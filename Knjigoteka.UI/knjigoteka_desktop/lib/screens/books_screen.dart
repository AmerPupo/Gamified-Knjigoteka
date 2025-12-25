import 'package:flutter/material.dart';
import 'package:knjigoteka_desktop/screens/book_form_dialog.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/language.dart';
import '../providers/book_provider.dart';
import '../providers/genre_provider.dart';
import '../providers/language_provider.dart';

class BooksScreen extends StatefulWidget {
  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  List<Book> _books = [];
  List<Genre> _genres = [];
  List<Language> _languages = [];
  bool _loading = true;
  int? _hoveredRowIndex;
  Offset? _mousePosition;
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: 'http://localhost:7295/api',
  );
  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    _genres = await GenreProvider().getGenres();
    _languages = await LanguageProvider().getLanguages();
    _books = await BookProvider().getBooks();
    setState(() => _loading = false);
  }

  void _openForm({Book? book}) async {
    await showDialog(
      context: context,
      builder: (_) => BookFormDialog(
        book: book,
        genres: _genres,
        languages: _languages,
        onSaved: _loadAll,
      ),
    );
  }

  void _confirmDelete(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Brisanje knjige"),
        content: Text(
          "Da li ste sigurni da želite obrisati knjigu '${book.title}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Odustani"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text("Obriši"),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await BookProvider().deleteBook(book.id);
      _loadAll();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Knjiga obrisana.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Knjige',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Pretraži po nazivu ili autoru...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) async {
                        setState(() => _loading = true);
                        _books = await BookProvider().getBooks(fts: v);
                        setState(() => _loading = false);
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _openForm,
                    icon: Icon(Icons.add),
                    label: Text("Dodaj novu"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF233348),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      textStyle: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18),
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator())
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                              minHeight: constraints.maxHeight,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: constraints.maxWidth < 1100
                                  ? Axis.horizontal
                                  : Axis.vertical,
                              child: SizedBox(
                                width: constraints.maxWidth,
                                child: DataTable(
                                  columnSpacing: 28,
                                  headingRowColor: MaterialStateProperty.all(
                                    Colors.grey.shade200,
                                  ),
                                  dataRowColor: MaterialStateProperty.all(
                                    Colors.white,
                                  ),
                                  columns: [
                                    DataColumn(label: Text("Naziv")),
                                    DataColumn(label: Text("Autor")),
                                    DataColumn(label: Text("Žanr")),
                                    DataColumn(label: Text("Jezik")),
                                    DataColumn(label: Text("Godina")),
                                    DataColumn(label: Text("Količina")),
                                    DataColumn(label: Text("Cijena")),
                                    DataColumn(label: Text("Uredi")),
                                    DataColumn(label: Text("Obriši")),
                                  ],
                                  rows: List<DataRow>.generate(
                                    _books.length,
                                    (index) => DataRow(
                                      cells: [
                                        DataCell(
                                          MouseRegion(
                                            onHover: (event) {
                                              setState(() {
                                                _hoveredRowIndex = index;
                                                _mousePosition = event.position;
                                              });
                                            },
                                            onExit: (_) {
                                              setState(() {
                                                _hoveredRowIndex = null;
                                                _mousePosition = null;
                                              });
                                            },
                                            child: Text(_books[index].title),
                                          ),
                                        ),
                                        DataCell(Text(_books[index].author)),
                                        DataCell(Text(_books[index].genreName)),
                                        DataCell(
                                          Text(_books[index].languageName),
                                        ),
                                        DataCell(
                                          Text(_books[index].year.toString()),
                                        ),
                                        DataCell(
                                          Text(
                                            _books[index]
                                                .calculatedTotalQuantity
                                                .toString(),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            "${_books[index].price.toStringAsFixed(2)} KM",
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () =>
                                                _openForm(book: _books[index]),
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _confirmDelete(_books[index]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          if (_hoveredRowIndex != null && _mousePosition != null)
            Positioned(
              left: _mousePosition!.dx - 90,
              top: _mousePosition!.dy - 40,
              child: IgnorePointer(
                ignoring: true,
                child: Material(
                  color: Colors.transparent,
                  elevation: 8,
                  child: Container(
                    width: 150,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 16),
                      ],
                    ),
                    child: _books[_hoveredRowIndex!].hasImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              "$_baseUrl${_books[_hoveredRowIndex!].photoEndpoint}",
                              width: 150,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
