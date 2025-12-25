import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/language.dart';
import '../providers/book_provider.dart';

class BookFormDialog extends StatefulWidget {
  final Book? book;
  final List<Genre> genres;
  final List<Language> languages;
  final VoidCallback onSaved;

  BookFormDialog({
    this.book,
    required this.genres,
    required this.languages,
    required this.onSaved,
  });

  @override
  State<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends State<BookFormDialog> {
  final _formKey = GlobalKey<FormState>();
  Uint8List? _imageBytes;
  String? _imageError;
  late TextEditingController _title;
  late TextEditingController _author;
  late TextEditingController _isbn;
  late TextEditingController _desc;
  late TextEditingController _qty;
  late TextEditingController _price;
  late TextEditingController _year;
  int? _genreId;
  int? _langId;
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: 'http://localhost:7295/api',
  );
  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _title = TextEditingController(text: b?.title ?? '');
    _author = TextEditingController(text: b?.author ?? '');
    _isbn = TextEditingController(text: b?.isbn ?? '');
    _desc = TextEditingController(text: b?.shortDescription ?? '');
    _qty = TextEditingController(text: b?.centralStock.toString() ?? '');
    _price = TextEditingController(text: b?.price.toString() ?? '');
    _year = TextEditingController(text: b?.year.toString() ?? '');
    _genreId = b?.genreId;
    _langId = b?.languageId;
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null) {
      Uint8List? bytes = result.files.single.bytes;
      if (bytes == null && result.files.single.path != null) {
        bytes = await File(result.files.single.path!).readAsBytes();
      }
      if (bytes != null) {
        setState(() {
          _imageBytes = bytes;
          _imageError = null;
        });
      } else {
        setState(() => _imageError = "Nije moguće učitati sliku.");
      }
    }
  }

  void _save() async {
    bool valid = _formKey.currentState!.validate();
    if (widget.book == null && _imageBytes == null) {
      setState(() => _imageError = "Slika knjige je obavezna!");
      valid = false;
    } else {
      setState(() => _imageError = null);
    }
    if (!valid) return;

    final req = {
      "title": _title.text,
      "author": _author.text,
      "genreId": _genreId!,
      "languageId": _langId!,
      "isbn": _isbn.text,
      "year": int.tryParse(_year.text) ?? 0,
      "centralStock": int.tryParse(_qty.text) ?? 0,
      "shortDescription": _desc.text,
      "price": double.tryParse(_price.text) ?? 0,
      "bookImage": _imageBytes != null ? base64Encode(_imageBytes!) : null,
    };

    if (widget.book == null) {
      await BookProvider().addBook(req);
    } else {
      await BookProvider().updateBook(widget.book!.id, req);
    }
    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Responsive width/height
    final media = MediaQuery.of(context);
    final maxDialogWidth = media.size.width * 0.40;
    final maxDialogHeight = media.size.height * 0.85;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: media.size.width * 0.18,
        vertical: media.size.height * 0.08,
      ),
      backgroundColor: Color(0xFFF7F0F7),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxDialogWidth,
          maxHeight: maxDialogHeight,
          minWidth: 370,
          minHeight: 380,
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image + okvir
              Column(
                children: [
                  Text(
                    'Fotografija',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 130,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.deepPurple.shade200,
                          width: 2.3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.13),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.cover,
                                width: 130,
                                height: 180,
                              ),
                            )
                          : widget.book != null &&
                                widget.book!.hasImage &&
                                widget.book!.photoEndpoint.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.network(
                                "$_baseUrl${widget.book!.photoEndpoint}",
                                fit: BoxFit.cover,
                                width: 130,
                                height: 180,
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.upload,
                                size: 55,
                                color: Colors.grey[400],
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 7),
                  if (_imageError != null)
                    Text(
                      _imageError!,
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  Text(
                    'Klikni za promjenu slike',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              SizedBox(width: 34),
              // Forma (scrollable)
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.book == null ? 'Dodaj knjigu' : 'Uredi knjigu',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        TextFormField(
                          controller: _title,
                          decoration: InputDecoration(labelText: 'Naziv'),
                          validator: (v) =>
                              v!.isEmpty ? 'Obavezno polje' : null,
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _author,
                          decoration: InputDecoration(labelText: 'Autor'),
                          validator: (v) =>
                              v!.isEmpty ? 'Obavezno polje' : null,
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _isbn,
                          decoration: InputDecoration(labelText: 'ISBN'),
                          validator: (v) =>
                              v!.isEmpty ? 'Obavezno polje' : null,
                        ),
                        SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          value: _genreId,
                          items: widget.genres
                              .map(
                                (g) => DropdownMenuItem(
                                  value: g.id,
                                  child: Text(g.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _genreId = v),
                          decoration: InputDecoration(labelText: 'Žanr'),
                          validator: (v) => v == null ? 'Obavezno polje' : null,
                        ),
                        SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          value: _langId,
                          items: widget.languages
                              .map(
                                (l) => DropdownMenuItem(
                                  value: l.id,
                                  child: Text(l.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _langId = v),
                          decoration: InputDecoration(labelText: 'Jezik'),
                          validator: (v) => v == null ? 'Obavezno polje' : null,
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _desc,
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(labelText: 'Opis'),
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _qty,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Količina'),
                          validator: (v) =>
                              v!.isEmpty ? 'Obavezno polje' : null,
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _price,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Cijena'),
                          validator: (v) =>
                              v!.isEmpty ? 'Obavezno polje' : null,
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _year,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Godina'),
                          validator: (v) =>
                              v!.isEmpty ? 'Obavezno polje' : null,
                        ),
                        SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: _save,
                              child: Text('Sačuvaj'),
                            ),
                            SizedBox(width: 12),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Prekid'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
