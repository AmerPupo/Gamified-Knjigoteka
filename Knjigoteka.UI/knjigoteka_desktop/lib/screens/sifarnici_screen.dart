import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/genre.dart';
import '../models/language.dart';
import '../models/city.dart';
import '../providers/genre_provider.dart';
import '../providers/language_provider.dart';
import '../providers/city_provider.dart';

class SifarniciScreen extends StatefulWidget {
  @override
  State<SifarniciScreen> createState() => _SifarniciScreenState();
}

class _SifarniciScreenState extends State<SifarniciScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;

  List<Genre> genres = [];
  List<Language> languages = [];
  List<City> cities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    genres = await Provider.of<GenreProvider>(
      context,
      listen: false,
    ).getGenres();
    languages = await Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).getLanguages();
    cities = await Provider.of<CityProvider>(
      context,
      listen: false,
    ).searchCities();
    setState(() => _loading = false);
  }

  Future<void> _showEditDialog({
    required String title,
    String? initialValue,
    required Function(String) onSave,
  }) async {
    final ctrl = TextEditingController(text: initialValue ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Naziv'),
            validator: (v) => v!.trim().isEmpty ? "Obavezno polje" : null,
          ),
        ),
        actions: [
          TextButton(
            child: Text("Otkaži"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: Text("Sačuvaj"),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                onSave(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTab<T>({
    required String label,
    required List<T> items,
    required String Function(T) getName,
    required Future<void> Function(String) onAdd,
    required Future<void> Function(T, String) onEdit,
    required Future<void> Function(T) onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text("Dodaj"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF233348),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await _showEditDialog(
                    title: "Dodaj $label",
                    onSave: (naziv) async {
                      await onAdd(naziv);
                      await _loadAll();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("$label dodan!")));
                    },
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 18),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(blurRadius: 16, color: Colors.black12),
                      ],
                    ),
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (_, idx) {
                        final item = items[idx];
                        return ListTile(
                          title: Text(getName(item)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  await _showEditDialog(
                                    title: "Uredi $label".toLowerCase(),
                                    initialValue: getName(item),
                                    onSave: (noviNaziv) async {
                                      await onEdit(item, noviNaziv);
                                      await _loadAll();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text("$label izmijenjen!"),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirmed = await showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(
                                        "Brisanje $label"
                                        "a",
                                      ),
                                      content: Text(
                                        "Da li ste sigurni da želite obrisati '${getName(item)}'?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: Text("Odustani"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: Text("Obriši"),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await onDelete(item);
                                    await _loadAll();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("$label obrisan!"),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addGenre(String naziv) async =>
      await Provider.of<GenreProvider>(
        context,
        listen: false,
      ).insert({'name': naziv});
  Future<void> _editGenre(Genre g, String naziv) async =>
      await Provider.of<GenreProvider>(
        context,
        listen: false,
      ).update(g.id, {'name': naziv});
  Future<void> _deleteGenre(Genre g) async =>
      await Provider.of<GenreProvider>(context, listen: false).delete(g.id);

  Future<void> _addLanguage(String naziv) async =>
      await Provider.of<LanguageProvider>(
        context,
        listen: false,
      ).insert({'name': naziv});
  Future<void> _editLanguage(Language l, String naziv) async =>
      await Provider.of<LanguageProvider>(
        context,
        listen: false,
      ).update(l.id, {'name': naziv});
  Future<void> _deleteLanguage(Language l) async =>
      await Provider.of<LanguageProvider>(context, listen: false).delete(l.id);

  Future<void> _addCity(String naziv) async => await Provider.of<CityProvider>(
    context,
    listen: false,
  ).insert({'name': naziv});
  Future<void> _editCity(City c, String naziv) async =>
      await Provider.of<CityProvider>(
        context,
        listen: false,
      ).update(c.id, {'name': naziv});
  Future<void> _deleteCity(City c) async =>
      await Provider.of<CityProvider>(context, listen: false).delete(c.id);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            "Šifarnici",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222B45),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Color(0xFF233348),
            labelColor: Color(0xFF233348),
            unselectedLabelColor: Colors.black45,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Žanrovi"),
              Tab(text: "Jezici"),
              Tab(text: "Gradovi"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTab<Genre>(
                label: "Žanr",
                items: genres,
                getName: (g) => g.name,
                onAdd: _addGenre,
                onEdit: _editGenre,
                onDelete: _deleteGenre,
              ),
              _buildTab<Language>(
                label: "Jezik",
                items: languages,
                getName: (l) => l.name,
                onAdd: _addLanguage,
                onEdit: _editLanguage,
                onDelete: _deleteLanguage,
              ),
              _buildTab<City>(
                label: "Grad",
                items: cities,
                getName: (c) => c.name,
                onAdd: _addCity,
                onEdit: _editCity,
                onDelete: _deleteCity,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
