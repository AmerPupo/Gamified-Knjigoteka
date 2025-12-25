import 'dart:async';
import 'package:flutter/material.dart';
import 'package:knjigoteka_mobile/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/language.dart';
import '../providers/book_provider.dart';
import '../providers/genre_provider.dart';
import '../providers/language_provider.dart';

class HomeScreen extends StatefulWidget {
  final void Function(Book) onBookTap;
  const HomeScreen({required this.onBookTap});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Book> _books = [];
  String _search = '';
  bool _loading = false;
  Genre? _selectedGenre;
  Language? _selectedLanguage;
  List<Genre> _genres = [];
  List<Language> _languages = [];
  Timer? _debounce;
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://10.0.2.2:7295/api",
  );
  @override
  void initState() {
    super.initState();
    _loadFilters();
    _fetchBooks();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    final genres = await Provider.of<GenreProvider>(
      context,
      listen: false,
    ).getAll();
    final languages = await Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).getAll();
    setState(() {
      _genres = genres;
      _languages = languages;
    });
  }

  Future<void> _fetchBooks() async {
    setState(() => _loading = true);
    try {
      final books = await Provider.of<BookProvider>(context, listen: false)
          .getBooks(
            fts: _search,
            genreId: _selectedGenre?.id,
            languageId: _selectedLanguage?.id,
          );
      setState(() => _books = books);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Greška: ${e.toString()}')));
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _showFilters() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _FilterSheet(
        genres: _genres,
        languages: _languages,
        selectedGenre: _selectedGenre,
        selectedLanguage: _selectedLanguage,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedGenre = result['genre'] as Genre?;
        _selectedLanguage = result['language'] as Language?;
      });
      _fetchBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFF3F6FA),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      child: TextField(
                        onChanged: (val) {
                          _search = val;
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(
                            const Duration(milliseconds: 500),
                            () {
                              _fetchBooks();
                            },
                          );
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Pretraži knjige ili autore...',
                          contentPadding: EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                          filled: true,
                          fillColor: Color(0xFFF3F6FA),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showFilters,
                    icon: Icon(Icons.filter_list, size: 20),
                    label: Text('Filteri', style: TextStyle(fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF233348),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchBooks,
                child: _loading
                    ? Center(child: CircularProgressIndicator())
                    : _books.isEmpty
                    ? Center(
                        child: Text(
                          'Nema knjiga za prikaz',
                          style: TextStyle(fontSize: 17),
                        ),
                      )
                    : ListView.separated(
                        physics: AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(top: 10, bottom: 20),
                        itemCount: _books.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12),
                        itemBuilder: (ctx, idx) {
                          final b = _books[idx];
                          return GestureDetector(
                            onTap: () {
                              widget.onBookTap(b);
                            },
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 75,
                                    height: 105,
                                    margin: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF3F6FA),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: b.hasImage
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              "$_baseUrl${b.photoEndpoint}",
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Icon(
                                                    Icons.menu_book,
                                                    size: 40,
                                                    color: Colors.grey[400],
                                                  ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.menu_book,
                                            size: 40,
                                            color: Colors.grey[400],
                                          ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: 12,
                                        top: 15,
                                        bottom: 15,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            b.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            b.author,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '${b.price.toStringAsFixed(2)} KM',
                                            style: TextStyle(
                                              color: Colors.indigo,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          SizedBox(height: 7),
                                          SizedBox(
                                            width: double.infinity,
                                            child: CartStepperInline(book: b),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final List<Genre> genres;
  final List<Language> languages;
  final Genre? selectedGenre;
  final Language? selectedLanguage;
  const _FilterSheet({
    required this.genres,
    required this.languages,
    this.selectedGenre,
    this.selectedLanguage,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  Genre? _genre;
  Language? _language;

  @override
  void initState() {
    super.initState();
    _genre = widget.selectedGenre;
    _language = widget.selectedLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20, left: 22, right: 22, bottom: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filteri',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<Genre>(
            decoration: InputDecoration(
              labelText: 'Žanr',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            value: _genre,
            isExpanded: true,
            items: [
              DropdownMenuItem(child: Text('Svi žanrovi'), value: null),
              ...widget.genres.map(
                (g) => DropdownMenuItem(child: Text(g.name), value: g),
              ),
            ],
            onChanged: (val) => setState(() => _genre = val),
          ),
          SizedBox(height: 15),
          DropdownButtonFormField<Language>(
            decoration: InputDecoration(
              labelText: 'Jezik',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            value: _language,
            isExpanded: true,
            items: [
              DropdownMenuItem(child: Text('Svi jezici'), value: null),
              ...widget.languages.map(
                (l) => DropdownMenuItem(child: Text(l.name), value: l),
              ),
            ],
            onChanged: (val) => setState(() => _language = val),
          ),
          SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'genre': _genre,
                'language': _language,
              }),
              child: Text('Primijeni'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF233348),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                textStyle: TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CartStepperInline extends StatefulWidget {
  final Book book;
  const CartStepperInline({required this.book});
  @override
  State<CartStepperInline> createState() => _CartStepperInlineState();
}

class _CartStepperInlineState extends State<CartStepperInline> {
  int _qty = 0;
  bool _loading = true;

  int get _maxQty => widget.book.centralStock;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final qty = await CartProvider().getBookQuantity(widget.book.id);
      if (!mounted) return;
      setState(() {
        _qty = qty;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _update(int n) async {
    if (n > _maxQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Na stanju je samo $_maxQty komada ove knjige."),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await CartProvider().upsertCartItem(bookId: widget.book.id, quantity: n);
      if (!mounted) return;
      setState(() {
        _qty = n;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = 13.0;
    final primary = Color(0xFF233348);

    if (_loading) {
      return Center(
        child: SizedBox(
          height: 30,
          width: 30,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_qty == 0) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(Icons.add_shopping_cart, size: 22),
          label: Text('Dodaj u korpu', style: TextStyle(fontSize: 16)),
          onPressed: _maxQty > 0 ? () async => await _update(1) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.10),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 7, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _qty == 1
                ? () async => await _update(0)
                : () async => await _update(_qty - 1),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
              ),
              padding: EdgeInsets.all(5),
              child: Icon(
                _qty == 1 ? Icons.delete_outline : Icons.remove,
                color: primary,
                size: 24,
              ),
            ),
          ),
          Text(
            '$_qty kom.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          GestureDetector(
            onTap: _qty < _maxQty
                ? () async => await _update(_qty + 1)
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Ne može više od $_maxQty komada. Toliko ih je trenutno na stanju.",
                        ),
                      ),
                    );
                  },
            child: Container(
              decoration: BoxDecoration(
                color: _qty < _maxQty ? Colors.white : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(9),
              ),
              padding: EdgeInsets.all(5),
              child: Icon(
                Icons.add,
                color: _qty < _maxQty ? primary : Colors.grey,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
