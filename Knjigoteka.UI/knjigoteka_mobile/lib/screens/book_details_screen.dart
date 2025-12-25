import 'package:flutter/material.dart';
import 'package:knjigoteka_mobile/models/branch_inventory.dart';
import 'package:knjigoteka_mobile/providers/book_provider.dart';
import 'package:knjigoteka_mobile/providers/reservation_provider.dart';
import 'package:knjigoteka_mobile/providers/branch_inventory_provider.dart';
import 'package:knjigoteka_mobile/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import 'package:knjigoteka_mobile/providers/notification_request_provider.dart';
import '../providers/auth_provider.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;
  final VoidCallback onClose;
  const BookDetailsScreen({required this.book, required this.onClose});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  int _quantity = 1;
  int _cartQuantity = 0;
  bool _loadingCartQty = false;
  bool _showAvailability = false;
  List<BranchInventory> _availability = [];
  bool _loadingAvailability = false;
  List<Book> _recommendedBooks = [];
  bool _loadingRecommended = false;
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://10.0.2.2:7295/api",
  );

  @override
  void initState() {
    super.initState();
    _loadCartQuantity();
    _fetchRecommendedBooks();
  }

  Future<void> _fetchRecommendedBooks() async {
    setState(() => _loadingRecommended = true);
    try {
      final books = await Provider.of<BookProvider>(
        context,
        listen: false,
      ).getRecommendedBooks(widget.book.id, take: 3);
      if (!mounted) return;
      setState(() {
        _recommendedBooks = books;
        _loadingRecommended = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRecommended = false);
      print(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška prilikom preuzimanja preporuka.')),
      );
    }
  }

  Future<void> _loadCartQuantity() async {
    setState(() => _loadingCartQty = true);
    try {
      final qty = await CartProvider().getBookQuantity(widget.book.id);
      if (!mounted) return;
      setState(() {
        _cartQuantity = qty;
        _loadingCartQty = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCartQty = false);
    }
  }

  Future<void> _fetchAvailability() async {
    setState(() {
      _loadingAvailability = true;
    });
    try {
      final list = await Provider.of<BranchInventoryProvider>(
        context,
        listen: false,
      ).getAvailabilityByBookId(widget.book.id);
      if (!mounted) return;
      setState(() {
        _availability = list;
        _loadingAvailability = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingAvailability = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Greška: $e')));
    }
  }

  void _showReservationDialog(BranchInventory bi) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Potvrda rezervacije"),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.black, fontSize: 15),
            children: [
              TextSpan(text: "Potvrdite rezervaciju knjige: "),
              TextSpan(
                text: widget.book.title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: " u poslovnici: "),
              TextSpan(
                text: bi.branchName ?? "",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    ".\n\nNakon potvrđivanja knjiga će Vam biti dostupna 48 sati za preuzimanje.\nU slučaju da ne otkažete rezervaciju i ne podignete knjigu, vaš račun će biti penaliziran.",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Odustani"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final token = AuthProvider.token!;
                await ReservationProvider().createReservation(
                  bookId: widget.book.id,
                  branchId: bi.branchId,
                  token: token,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Rezervacija uspješna!")),
                );
              } catch (e) {
                String msg = e.toString();
                print(msg);
                if (msg.contains('imate aktivnu')) {
                  msg = "Već imate aktivnu rezervaciju za ovu knjigu.";
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
            child: Text("Rezerviši"),
          ),
        ],
      ),
    );
  }

  void _showNotifyDialog(BranchInventory bi) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Obavijesti me"),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.black, fontSize: 15),
            children: [
              TextSpan(text: "Knjiga: "),
              TextSpan(
                text: widget.book.title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: " trenutno nije dostupna u poslovnici: "),
              TextSpan(
                text: bi.branchName ?? "",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    ".\n\nKlikom na dugme 'Obavijesti me' bićete automatski informisani čim knjiga bude dostupna za rezervaciju.",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Odustani"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final token = AuthProvider.token!;
                await NotificationRequestProvider().createNotificationRequest(
                  bookId: widget.book.id,
                  branchId: bi.branchId,
                  token: token,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Zahtjev za obavijest kreiran!")),
                );
              } catch (e) {
                String msg = e.toString();
                if (msg.startsWith('Exception: ')) {
                  msg = msg.replaceFirst('Exception: ', '');
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
            child: Text("Obavijesti me"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.book;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFF3F6FA),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Color(0xFF233348),
                        size: 27,
                      ),
                      onPressed: widget.onClose,
                    ),
                    SizedBox(width: 5),
                    Text(
                      "Detalji knjige",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF233348),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  height: 210,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: b.hasImage
                      ? Image.network(
                          "$_baseUrl${b.photoEndpoint}",
                          fit: BoxFit.contain,
                        )
                      : Icon(
                          Icons.menu_book,
                          size: 90,
                          color: Colors.grey[400],
                        ),
                ),
                SizedBox(height: 14),
                Text(
                  b.title,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  b.author,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 8),
                Text(
                  b.shortDescription,
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      b.averageRating!.toStringAsFixed(1),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 3),
                    Row(
                      children: List.generate(5, (i) {
                        final full = b.averageRating! >= i + 1;
                        final half =
                            b.averageRating! > i && b.averageRating! < i + 1;
                        return Icon(
                          full
                              ? Icons.star
                              : half
                              ? Icons.star_half
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 19,
                        );
                      }),
                    ),
                    SizedBox(width: 7),
                    Text(
                      "(${b.reviewsCount})",
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                if (!_showAvailability)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF233348),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        textStyle: TextStyle(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      onPressed: () async {
                        setState(() => _showAvailability = true);
                        await _fetchAvailability();
                      },
                      child: Text("Provjeri dostupnost u radnjama"),
                    ),
                  ),
                if (_showAvailability)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () =>
                              setState(() => _showAvailability = false),
                          child: Text("Zatvori dostupnost u radnjama"),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: EdgeInsets.all(13),
                        child: _loadingAvailability
                            ? Center(child: CircularProgressIndicator())
                            : _availability.isEmpty
                            ? Text("Nema informacija o dostupnosti.")
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Dostupno u sljedećim poslovnicama:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 9),
                                  Column(
                                    children: _availability
                                        .where((bi) => bi.supportsBorrowing)
                                        .map((bi) {
                                          final available =
                                              bi.quantityForBorrow > 0;
                                          return Card(
                                            color: available
                                                ? Color(0xFFEFFEED)
                                                : Color(0xFFFFEFEF),
                                            child: ListTile(
                                              title: Text(
                                                bi.branchName ?? "N/A",
                                              ),
                                              subtitle: Text(
                                                "Adresa: ${bi.branchAddress ?? "N/A"}",
                                              ),
                                              trailing: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: available
                                                      ? Colors.green
                                                      : Colors.red,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () {
                                                  if (available) {
                                                    _showReservationDialog(bi);
                                                  } else {
                                                    _showNotifyDialog(bi);
                                                  }
                                                },
                                                child: Text(
                                                  available
                                                      ? "Rezerviši"
                                                      : "Obavijesti me",
                                                ),
                                              ),
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                SizedBox(height: 17),
                SizedBox(
                  width: double.infinity,
                  child: (_cartQuantity > 0)
                      ? AnimatedContainer(
                          duration: Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.symmetric(
                            vertical: 9,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFF233348),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 11,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: _cartQuantity == 1
                                    ? () async {
                                        await CartProvider().upsertCartItem(
                                          bookId: widget.book.id,
                                          quantity: 0,
                                        );
                                        setState(() => _cartQuantity = 0);
                                      }
                                    : () async {
                                        await CartProvider().upsertCartItem(
                                          bookId: widget.book.id,
                                          quantity: _cartQuantity - 1,
                                        );
                                        setState(() => _cartQuantity -= 1);
                                      },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    _cartQuantity == 1
                                        ? Icons.delete_outline
                                        : Icons.remove,
                                    color: Color(0xFF233348),
                                    size: 26,
                                  ),
                                ),
                              ),
                              SizedBox(width: 34),
                              AnimatedSwitcher(
                                duration: Duration(milliseconds: 170),
                                child: Text(
                                  '$_cartQuantity',
                                  key: ValueKey<int>(_cartQuantity),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                transitionBuilder:
                                    (
                                      Widget child,
                                      Animation<double> animation,
                                    ) => ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                              ),
                              SizedBox(width: 34),
                              GestureDetector(
                                onTap: _cartQuantity < (b.centralStock)
                                    ? () async {
                                        await CartProvider().upsertCartItem(
                                          bookId: widget.book.id,
                                          quantity: _cartQuantity + 1,
                                        );
                                        setState(() => _cartQuantity += 1);
                                      }
                                    : () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Ne može više od ${(b.centralStock)} komada. Toliko ih je trenutno na stanju.",
                                            ),
                                          ),
                                        );
                                      },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _cartQuantity < (b.centralStock)
                                        ? Colors.white
                                        : Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    Icons.add,
                                    color: _cartQuantity < (b.centralStock)
                                        ? Color(0xFF233348)
                                        : Colors.grey,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: (b.centralStock) > 0
                              ? () async {
                                  await CartProvider().upsertCartItem(
                                    bookId: widget.book.id,
                                    quantity: _quantity,
                                  );
                                  setState(() => _cartQuantity = _quantity);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Dodano u korpu!")),
                                  );
                                }
                              : null,
                          icon: Icon(Icons.shopping_cart_outlined),
                          label: Text("Dodaj u korpu"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF233348),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                ),
                SizedBox(height: 20),
                Text(
                  "Specifikacije:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      "Kategorija:",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(width: 8),
                    Text(b.genreName),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Text("ISBN:", style: TextStyle(color: Colors.grey[700])),
                    SizedBox(width: 8),
                    Text(b.isbn),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Text("Jezik:", style: TextStyle(color: Colors.grey[700])),
                    SizedBox(width: 8),
                    Text(b.languageName),
                  ],
                ),
                SizedBox(height: 22),
                Text(
                  "Preporučene knjige:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                SizedBox(height: 10),
                _loadingRecommended
                    ? Center(child: CircularProgressIndicator())
                    : _recommendedBooks.isEmpty
                    ? Text("Nema preporuka za ovu knjigu.")
                    : SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _recommendedBooks.length,
                          separatorBuilder: (_, __) => SizedBox(width: 15),
                          itemBuilder: (_, i) {
                            final book = _recommendedBooks[i];
                            return GestureDetector(
                              onTap: () async {
                                // Povuci najnovije detalje knjige po ID-u
                                final fetchedBook =
                                    await Provider.of<BookProvider>(
                                      context,
                                      listen: false,
                                    ).getBook(book.id);

                                // Otvori novi ekran sa detaljima knjige
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BookDetailsScreen(
                                      book: fetchedBook,
                                      onClose: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 145,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                margin: EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(14),
                                      ),
                                      child: book.hasImage
                                          ? Image.network(
                                              "$_baseUrl${book.photoEndpoint}",
                                              height: 85,
                                              width: 145,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              height: 85,
                                              width: 145,
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons.menu_book,
                                                size: 36,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            book.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFF233348),
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            book.author,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            book.price.toStringAsFixed(2) +
                                                " KM",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF398346),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
