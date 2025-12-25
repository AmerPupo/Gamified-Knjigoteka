import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/branch_inventory.dart';
import '../providers/user_provider.dart';
import '../providers/branch_inventory_provider.dart';
import '../providers/auth_provider.dart';

class AddBorrowingDialog extends StatefulWidget {
  final Function(int userId, int bookId) onSave;
  const AddBorrowingDialog({required this.onSave});
  @override
  State<AddBorrowingDialog> createState() => _AddBorrowingDialogState();
}

class _AddBorrowingDialogState extends State<AddBorrowingDialog> {
  final _userController = TextEditingController();
  final _bookController = TextEditingController();
  User? _selectedUser;
  BranchInventory? _selectedBook;
  List<User> _users = [];
  List<BranchInventory> _books = [];
  bool _loadingUsers = false;
  bool _loadingBooks = false;
  final _formKey = GlobalKey<FormState>();
  Timer? _debounceUser;
  Timer? _debounceBook;

  void _fetchUsers(String query) {
    if (_debounceUser?.isActive ?? false) _debounceUser?.cancel();
    _debounceUser = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _loadingUsers = true);
      try {
        final result = await Provider.of<UserProvider>(
          context,
          listen: false,
        ).searchUsers(FTS: query);
        setState(() {
          _users = result;
        });
      } catch (_) {}
      setState(() => _loadingUsers = false);
    });
  }

  void _fetchBooks(String query) async {
    if (_debounceBook?.isActive ?? false) _debounceBook?.cancel();
    _debounceBook = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _loadingBooks = true);
      try {
        final branchId = Provider.of<AuthProvider>(
          context,
          listen: false,
        ).branchId!;
        final result = await Provider.of<BranchInventoryProvider>(
          context,
          listen: false,
        ).getAvailableForBorrow(branchId, fts: query);
        setState(() {
          _books = result
              .where((b) => b.supportsBorrowing && b.quantityForBorrow > 0)
              .toList();
        });
      } catch (_) {}
      setState(() => _loadingBooks = false);
    });
  }

  @override
  void dispose() {
    _userController.dispose();
    _bookController.dispose();
    _debounceUser?.cancel();
    _debounceBook?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = MediaQuery.of(context).size.width < 900 ? 400.0 : 480.0;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Dodaj posudbu",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Autocomplete<User>(
                  displayStringForOption: (user) =>
                      '${user.fullName} <${user.email}>',
                  optionsBuilder: (TextEditingValue value) {
                    if (value.text.length < 2)
                      return const Iterable<User>.empty();
                    _fetchUsers(value.text);
                    return _users.where(
                      (u) =>
                          u.fullName.toLowerCase().contains(
                            value.text.toLowerCase(),
                          ) ||
                          u.email.toLowerCase().contains(
                            value.text.toLowerCase(),
                          ),
                    );
                  },
                  onSelected: (user) {
                    setState(() {
                      _selectedUser = user;
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        _userController.value = controller.value;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Korisnik (ime ili email)',
                            border: OutlineInputBorder(),
                            suffixIcon: controller.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      controller.clear();
                                      setState(() {
                                        _selectedUser = null;
                                        _users = [];
                                      });
                                    },
                                  )
                                : null,
                          ),
                          validator: (val) => _selectedUser == null
                              ? 'Odaberi korisnika'
                              : null,
                          onChanged: (v) {
                            if (v.length < 2) {
                              setState(() {
                                _users = [];
                                _selectedUser = null;
                              });
                            }
                          },
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        child: SizedBox(
                          width: 400,
                          child: _loadingUsers
                              ? Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final User option = options.elementAt(
                                      index,
                                    );
                                    return ListTile(
                                      title: Text(option.fullName),
                                      subtitle: Text(option.email),
                                      onTap: () {
                                        onSelected(option);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                Autocomplete<BranchInventory>(
                  displayStringForOption: (book) =>
                      '${book.title} - ${book.author}',
                  optionsBuilder: (TextEditingValue value) {
                    if (value.text.length < 2)
                      return const Iterable<BranchInventory>.empty();
                    _fetchBooks(value.text);
                    return _books.where(
                      (b) =>
                          (b.title.toLowerCase().contains(
                                value.text.toLowerCase(),
                              ) ||
                              b.author.toLowerCase().contains(
                                value.text.toLowerCase(),
                              )) &&
                          b.supportsBorrowing &&
                          b.quantityForBorrow > 0,
                    );
                  },
                  onSelected: (book) {
                    setState(() {
                      _selectedBook = book;
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        _bookController.value = controller.value;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Knjiga (naslov ili autor)',
                            border: OutlineInputBorder(),
                            suffixIcon: controller.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      controller.clear();
                                      setState(() {
                                        _selectedBook = null;
                                        _books = [];
                                      });
                                    },
                                  )
                                : null,
                          ),
                          validator: (val) =>
                              _selectedBook == null ? 'Odaberi knjigu' : null,
                          onChanged: (v) {
                            if (v.length < 2) {
                              setState(() {
                                _books = [];
                                _selectedBook = null;
                              });
                            }
                          },
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        child: SizedBox(
                          width: 400,
                          child: _loadingBooks
                              ? Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final BranchInventory option = options
                                        .elementAt(index);
                                    return ListTile(
                                      title: Text(
                                        '${option.title} - ${option.author}',
                                      ),
                                      subtitle: Text(
                                        'Dostupno: ${option.quantityForBorrow}',
                                      ),
                                      onTap: () {
                                        onSelected(option);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Otkaži"),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        if (_selectedUser == null || _selectedBook == null)
                          return;
                        widget.onSave(_selectedUser!.id, _selectedBook!.bookId);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        textStyle: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: Text("Sačuvaj"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
