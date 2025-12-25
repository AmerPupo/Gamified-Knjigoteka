import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:knjigoteka_mobile/providers/review_provider.dart';
import '../providers/history_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order_response.dart';
import '../models/borrowing_response.dart';

class HistoryScreen extends StatefulWidget {
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = "Po datumu (najnovije)";
  List<OrderResponse> _orders = [];
  List<BorrowingResponse> _borrowings = [];
  bool _loading = true;
  List<int> _myReviewedBookIds = [];
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final token = await AuthProvider.token;
    final hp = HistoryProvider();
    final orders = await hp.getMyOrders("$token");
    final borrowings = await hp.getMyBorrowings("$token");
    final myReviews = await ReviewProvider().getMyReviews(token.toString());

    setState(() {
      _orders = orders;
      _borrowings = borrowings;
      _myReviewedBookIds = myReviews.map((r) => r.bookId).toList();
      _loading = false;
    });
  }

  bool isReviewed(dynamic bookId) {
    return _myReviewedBookIds.contains(bookId);
  }

  List<Map<String, dynamic>> _combineBooks() {
    final kupovine = _orders
        .expand(
          (o) => o.items.map(
            (item) => {
              "bookId": item.bookId,
              "title": item.title,
              "author": item.author ?? "",
              "status": "Kupljena",
              "date": o.createdAt,
              "imageUrl": item.photoEndpoint,
              "dueDays": null,
            },
          ),
        )
        .toList();

    final posudbe = _borrowings
        .map(
          (b) => {
            "bookId": b.bookId,
            "title": b.title,
            "author": b.author,
            "status": b.returnedAt != null
                ? "Posuđena - Vraćena"
                : "Posuđena - Aktivna",
            "date": b.borrowedAt,
            "imageUrl": b.photoEndpoint,
            "dueDays": b.returnedAt == null
                ? b.dueDate.difference(DateTime.now()).inDays
                : null,
          },
        )
        .toList();
    var sve = [...kupovine, ...posudbe];
    sve.sort((a, b) {
      switch (_sortBy) {
        case "Po datumu (najstarije)":
          return (a["date"] as DateTime).compareTo(b["date"] as DateTime);
        case "Po nazivu (A-Z)":
          return a["title"].toString().compareTo(b["title"].toString());
        case "Po nazivu (Z-A)":
          return b["title"].toString().compareTo(a["title"].toString());
        case "Po datumu (najnovije)":
        default:
          return (b["date"] as DateTime).compareTo(a["date"] as DateTime);
      }
    });
    return sve;
  }

  List<Map<String, dynamic>> _filterBooks(String tab) {
    List<Map<String, dynamic>> books;
    if (tab == "all") {
      books = _combineBooks();
    } else if (tab == "orders") {
      books = _orders
          .expand(
            (o) => o.items.map(
              (item) => {
                "title": item.title,
                "author": item.author ?? "",
                "status": "Kupljena",
                "date": o.createdAt,
                "imageUrl": item.photoEndpoint,
                "dueDays": null,
              },
            ),
          )
          .toList();
    } else {
      books = _borrowings
          .map(
            (b) => {
              "title": b.title,
              "author": b.author,
              "status": b.returnedAt != null
                  ? "Posuđena - Vraćena"
                  : "Posuđena - Aktivna",
              "date": b.borrowedAt,
              "imageUrl": b.photoEndpoint,
              "dueDays": b.returnedAt == null
                  ? b.dueDate.difference(DateTime.now()).inDays
                  : null,
            },
          )
          .toList();
    }

    books.sort((a, b) {
      switch (_sortBy) {
        case "Po datumu (najstarije)":
          return (a["date"] as DateTime).compareTo(b["date"] as DateTime);
        case "Po nazivu (A-Z)":
          return a["title"].toString().compareTo(b["title"].toString());
        case "Po nazivu (Z-A)":
          return b["title"].toString().compareTo(a["title"].toString());
        case "Po datumu (najnovije)":
        default:
          return (b["date"] as DateTime).compareTo(a["date"] as DateTime);
      }
    });

    return books;
  }

  void _showRatingDialog(BuildContext ctx, int bookId, String bookTitle) {
    double _rating = 3;
    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        title: Text("Ocijeni knjigu"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(bookTitle, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            RatingBar.builder(
              initialRating: 3,
              minRating: 1,
              maxRating: 5,
              itemCount: 5,
              allowHalfRating: false,
              itemBuilder: (context, _) =>
                  Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (r) => _rating = r,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Otkaži"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text("Pošalji"),
            onPressed: () async {
              final token = await AuthProvider.token;
              final ok = await ReviewProvider().submitReview(
                bookId: bookId,
                rating: _rating.toInt(),
                token: token.toString(),
              );
              Navigator.pop(context);
              if (ok) setState(() {}); // reload reviews
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Moje knjige"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Sve"),
            Tab(text: "Kupovine"),
            Tab(text: "Posudbe"),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Sortiraj",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    value: _sortBy,
                    items:
                        [
                              "Po datumu (najnovije)",
                              "Po datumu (najstarije)",
                              "Po nazivu (A-Z)",
                              "Po nazivu (Z-A)",
                            ]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                    onChanged: (v) {
                      setState(() => _sortBy = v!);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBooksGrid(_filterBooks("all")),
                      _buildBooksGrid(_filterBooks("orders")),
                      _buildBooksGrid(_filterBooks("borrowings")),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksGrid(List<Map<String, dynamic>> books) {
    if (books.isEmpty) {
      return Center(child: Text("Nema knjiga za prikaz."));
    }
    return GridView.builder(
      padding: EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.51,
        crossAxisSpacing: 12,
        mainAxisSpacing: 18,
      ),
      itemCount: books.length,
      itemBuilder: (_, idx) {
        final b = books[idx];
        return Card(
          elevation: 3,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 0.8,
                child: Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFFF3F6FA),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child:
                      b["imageUrl"] != null &&
                          (b["imageUrl"] as String).isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            "http://10.0.2.2:7295${b['imageUrl']}",
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.menu_book,
                              size: 55,
                              color: Colors.grey[350],
                            ),
                          ),
                        )
                      : Icon(
                          Icons.menu_book,
                          size: 55,
                          color: Colors.grey[350],
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b["title"] ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        b["author"] ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      Row(
                        children: [
                          Icon(Icons.event, size: 14, color: Colors.grey[500]),
                          SizedBox(width: 2),
                          Text(
                            b["date"] is String
                                ? b["date"]
                                : (b["date"] as DateTime).toString().split(
                                    " ",
                                  )[0],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        b["status"] ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: b["status"].toString().contains("Delivered")
                              ? Colors.indigo
                              : b["status"].toString().contains("Active")
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                      if ((b["status"] == "Delivered" ||
                              b["status"] == "Returned") &&
                          !isReviewed(b["bookId"]))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: OutlinedButton.icon(
                            icon: Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            label: Text('Ocijeni knjigu'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.amber),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              foregroundColor: Colors.amber[900],
                              minimumSize: Size(0, 34),
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                            ),
                            onPressed: () => _showRatingDialog(
                              context,
                              b["bookId"],
                              b["title"],
                            ),
                          ),
                        ),

                      if (b["dueDays"] != null)
                        Container(
                          margin: EdgeInsets.only(top: 2),
                          constraints: BoxConstraints(maxWidth: 120),
                          padding: EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            "Preostalo: ${b["dueDays"]} dana",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
