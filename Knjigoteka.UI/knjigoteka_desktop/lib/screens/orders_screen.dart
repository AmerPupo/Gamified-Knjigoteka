import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/restock_request_provider.dart';
import '../models/order.dart';
import '../models/restock_request.dart';

class OrdersScreen extends StatefulWidget {
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _restockSearch = '';
  String _orderSearch = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xfff7f9fb),
          appBar: AppBar(
            backgroundColor: const Color(0xfff7f9fb),
            elevation: 0,
            toolbarHeight: 100,
            titleSpacing: 0,
            automaticallyImplyLeading: false,
            title: Padding(
              padding: EdgeInsets.all(0),

              child: Text(
                'Narudžbe',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF233348),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(0),
              child: Container(
                color: Color(0xfff7f9fb),
                child: TabBar(
                  indicatorColor: Color(0xFF233348),
                  labelColor: Color(0xFF233348),
                  unselectedLabelColor: Colors.black45,
                  labelStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: [
                    Tab(text: "Restock zahtjevi"),
                    Tab(text: "Online narudžbe"),
                  ],
                ),
              ),
            ),
          ),
          body: Padding(
            padding: EdgeInsets.only(top: 24),
            child: TabBarView(
              children: [
                RestockRequestsTab(
                  search: _restockSearch,
                  onSearchChanged: (val) =>
                      setState(() => _restockSearch = val),
                ),
                OnlineOrdersTab(
                  search: _orderSearch,
                  onSearchChanged: (val) => setState(() => _orderSearch = val),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RestockRequestsTab extends StatefulWidget {
  final String search;
  final ValueChanged<String> onSearchChanged;
  const RestockRequestsTab({
    required this.search,
    required this.onSearchChanged,
  });

  @override
  State<RestockRequestsTab> createState() => _RestockRequestsTabState();
}

class _RestockRequestsTabState extends State<RestockRequestsTab> {
  bool _loading = true;
  String? _error;
  List<RestockRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provider = Provider.of<RestockRequestProvider>(
        context,
        listen: false,
      );
      final reqs = await provider.getAllRequests();
      setState(() => _requests = reqs);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  Future<void> _approve(int id) async {
    final provider = Provider.of<RestockRequestProvider>(
      context,
      listen: false,
    );
    final ok = await provider.approve(id);
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Zahtjev odobren!")));
      _loadRequests();
    }
  }

  Future<void> _reject(int id) async {
    final provider = Provider.of<RestockRequestProvider>(
      context,
      listen: false,
    );
    final ok = await provider.reject(id);
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Zahtjev odbijen.")));
      _loadRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.search.isEmpty
        ? _requests
        : _requests
              .where(
                (r) =>
                    r.status == RestockRequestStatus.pending &&
                    r.branchName.toLowerCase().contains(
                      widget.search.toLowerCase(),
                    ),
              )
              .toList();

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SEARCH
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pretraži narudžbe",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                SizedBox(height: 6),
                SizedBox(
                  width: 280,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Pretraži narudžbe",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      isDense: true,
                    ),
                    onChanged: widget.onSearchChanged,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // FULL WIDTH TABLE
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(_error!, style: TextStyle(color: Colors.red)),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 200,
                      child: DataTable(
                        columnSpacing: 44,
                        headingRowColor: MaterialStateProperty.resolveWith(
                          (states) => Colors.grey.shade300,
                        ),
                        dataRowColor: MaterialStateProperty.resolveWith(
                          (states) => Colors.white,
                        ),
                        columns: [
                          DataColumn(label: Text("Naziv poslovnice")),
                          DataColumn(label: Text("Datum zahtjeva")),
                          DataColumn(label: Text("Narudžba")),
                          DataColumn(label: Text("Potvrdi")),
                          DataColumn(label: Text("Odbij")),
                        ],
                        rows: filtered.map((r) {
                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color?>((
                              Set<MaterialState> states,
                            ) {
                              return r.status == RestockRequestStatus.pending
                                  ? Colors.white
                                  : Colors.grey.shade200;
                            }),
                            cells: [
                              DataCell(Text(r.branchName)),
                              DataCell(Text(r.requestedAt.toString())),
                              DataCell(
                                IconButton(
                                  icon: Icon(
                                    Icons.assignment,
                                    color: Colors.blue.shade900,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text("Stavka narudžbe"),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.close),
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                          ],
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text("Knjiga: ${r.bookTitle}"),
                                            SizedBox(height: 8),
                                            Text(
                                              "Količina: ${r.quantityRequested}",
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text("Zatvori"),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              DataCell(
                                r.status == RestockRequestStatus.pending
                                    ? Checkbox(
                                        value: false,
                                        onChanged: (_) => _approve(r.id),
                                      )
                                    : SizedBox.shrink(), // Nema checkbox-a!
                              ),
                              DataCell(
                                r.status == RestockRequestStatus.pending
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      "Odbij zahtjev",
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.close),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          false,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              content: Text(
                                                "Da li ste sigurni da želite odbiti ovaj zahtjev za restock?",
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
                                                  child: Text("Odbij"),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed == true) {
                                            await _reject(r.id);
                                          }
                                        },
                                      )
                                    : SizedBox.shrink(),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// --------------------
// 2. ONLINE ORDERS TAB
// --------------------
class OnlineOrdersTab extends StatefulWidget {
  final String search;
  final ValueChanged<String> onSearchChanged;
  const OnlineOrdersTab({required this.search, required this.onSearchChanged});

  @override
  State<OnlineOrdersTab> createState() => _OnlineOrdersTabState();
}

class _OnlineOrdersTabState extends State<OnlineOrdersTab> {
  bool _loading = true;
  String? _error;
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      final results = await provider.getAllOrders();
      setState(() => _orders = results);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  void _approveOrder(Order order) async {
    try {
      await Provider.of<OrderProvider>(
        context,
        listen: false,
      ).approveOrder(order.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Narudžba odobrena!")));
      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Greška: $e")));
    }
  }

  Future<void> _rejectOrder(Order order) async {
    try {
      await Provider.of<OrderProvider>(
        context,
        listen: false,
      ).rejectOrder(order.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Narudžba odbijena!")));
      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Greška: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.search.isEmpty
        ? _orders
        : _orders
              .where(
                (o) => o.items.any(
                  (i) => i.title.toLowerCase().contains(
                    widget.search.toLowerCase(),
                  ),
                ),
              )
              .toList();

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SEARCH
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pretraži narudžbe",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                SizedBox(height: 6),
                SizedBox(
                  width: 280,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Pretraži narudžbe",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      isDense: true,
                    ),
                    onChanged: widget.onSearchChanged,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // FULL WIDTH TABLE
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(_error!, style: TextStyle(color: Colors.red)),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 200,
                      child: DataTable(
                        columnSpacing: 44,
                        headingRowColor: MaterialStateProperty.resolveWith(
                          (states) => Colors.grey.shade300,
                        ),
                        dataRowColor: MaterialStateProperty.resolveWith(
                          (states) => Colors.white,
                        ),
                        columns: [
                          DataColumn(label: Text("Ime i prezime")),
                          DataColumn(label: Text("Datum zahtjeva")),
                          DataColumn(label: Text("Narudžba")),
                          DataColumn(label: Text("Potvrdi")),
                          DataColumn(label: Text("Odbij")),
                        ],
                        rows: filtered.map((o) {
                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color?>((
                              Set<MaterialState> states,
                            ) {
                              if (o.status == OrderStatus.approved)
                                return Colors.grey.shade200;
                              return Colors.white;
                            }),
                            cells: [
                              DataCell(Text(o.userName)),
                              DataCell(
                                Text(o.createdAt.toString().substring(0, 10)),
                              ),
                              DataCell(
                                IconButton(
                                  icon: Icon(
                                    Icons.assignment,
                                    color: Colors.blue.shade900,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text("Stavke narudžbe"),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.close),
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                          ],
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ...o.items.map(
                                              (item) => Text(
                                                "${item.title} x${item.quantity} (${item.unitPrice.toStringAsFixed(2)} KM/kom)",
                                              ),
                                            ),
                                            SizedBox(height: 12),
                                            Divider(),
                                            Text(
                                              "Ukupno: ${o.totalAmount.toStringAsFixed(2)} KM",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text("Zatvori"),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              DataCell(
                                o.status == OrderStatus.pending
                                    ? Checkbox(
                                        value: false,
                                        onChanged: (_) => _approveOrder(o),
                                      )
                                    : SizedBox.shrink(),
                              ),
                              DataCell(
                                o.status == OrderStatus.pending
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      "Odbij narudžbu",
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.close),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          false,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              content: Text(
                                                "Da li ste sigurni da želite odbiti ovu online narudžbu?",
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
                                                  child: Text("Odbij"),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed == true) {
                                            await _rejectOrder(o);
                                          }
                                        },
                                      )
                                    : SizedBox.shrink(),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
