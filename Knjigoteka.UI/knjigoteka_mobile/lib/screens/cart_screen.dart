import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:knjigoteka_mobile/models/cart_response.dart';
import 'package:knjigoteka_mobile/providers/auth_provider.dart';
import 'package:knjigoteka_mobile/providers/cart_provider.dart';
import 'package:knjigoteka_mobile/providers/order_provider.dart';
import 'package:knjigoteka_mobile/providers/stripe_service.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  CartResponse? _cart;
  bool _loading = true;
  bool _updating = false;
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://10.0.2.2:7295/api",
  );
  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _loading = true);
    try {
      final cart = await CartProvider().getCart();
      setState(() {
        _cart = cart;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateQuantity(int bookId, int qty) async {
    setState(() => _updating = true);
    await CartProvider().upsertCartItem(bookId: bookId, quantity: qty);
    await _loadCart();
    setState(() => _updating = false);
  }

  Future<void> _removeItem(int bookId) async {
    setState(() => _updating = true);
    await CartProvider().upsertCartItem(bookId: bookId, quantity: 0);
    await _loadCart();
    setState(() => _updating = false);
  }

  double get _total =>
      _cart?.items.fold<double>(
        0,
        (s, e) => s + ((e.unitPrice) * (e.quantity)),
      ) ??
      0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Korpa")),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : (_cart == null || _cart!.items.isEmpty)
          ? Center(child: Text("Vaša korpa je prazna."))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: _cart!.items.length,
                    separatorBuilder: (_, __) => Divider(),
                    itemBuilder: (context, idx) {
                      final item = _cart!.items[idx];
                      return ListTile(
                        leading: item.photoEndpoint != null
                            ? Image.network(
                                "$_baseUrl${item.photoEndpoint}",
                                fit: BoxFit.contain,
                              )
                            : Icon(
                                Icons.menu_book,
                                size: 40,
                                color: Colors.grey,
                              ),
                        title: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.author,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              "${item.unitPrice.toStringAsFixed(2)} KM",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    item.quantity == 1
                                        ? Icons.delete_outline
                                        : Icons.remove,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: _updating
                                      ? null
                                      : () {
                                          if (item.quantity == 1) {
                                            _removeItem(item.bookId);
                                          } else {
                                            _updateQuantity(
                                              item.bookId,
                                              item.quantity - 1,
                                            );
                                          }
                                        },
                                ),
                                Text(
                                  "${item.quantity}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add, color: Colors.green),
                                  onPressed: _updating
                                      ? null
                                      : () {
                                          _updateQuantity(
                                            item.bookId,
                                            item.quantity + 1,
                                          );
                                        },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Ukupno:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${_total.toStringAsFixed(2)} KM",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.payment),
                      label: Text("Nastavi na plaćanje"),
                      onPressed: _updating
                          ? null
                          : () async {
                              final user = await Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              ).fullName;
                              await showDialog(
                                context: context,
                                builder: (_) => CheckoutDialog(
                                  totalAmount: _total,
                                  ime: user.toString(),
                                  onKes:
                                      ({
                                        required adresa,
                                        required grad,
                                        required postanskiBroj,
                                        required nacinPlacanja,
                                      }) async {
                                        try {
                                          await OrderProvider().checkoutOrder(
                                            adresa: adresa,
                                            grad: grad,
                                            postanskiBroj: postanskiBroj,
                                            nacinPlacanja: nacinPlacanja,
                                          );
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Narudžba zaprimljena!",
                                                ),
                                              ),
                                            );
                                            await _loadCart();
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  e.toString().replaceFirst(
                                                    "Exception: ",
                                                    "",
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                  onKartica:
                                      ({
                                        required adresa,
                                        required grad,
                                        required postanskiBroj,
                                        required nacinPlacanja,
                                      }) async {
                                        dev.log(
                                          'Calling StripeService.processPayment...',
                                          name: 'PAY',
                                        );
                                        bool _isProcessing = true;
                                        try {
                                          final success =
                                              await StripeService.processPayment(
                                                amount: _total,
                                                currency: 'usd',
                                              ).timeout(
                                                const Duration(seconds: 60),
                                              );
                                          dev.log(
                                            'Stripe returned: $success',
                                            name: 'PAY',
                                          );
                                          if (!success) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Plaćanje otkazano.',
                                                ),
                                              ),
                                            );
                                            if (mounted)
                                              setState(
                                                () => _isProcessing = false,
                                              );
                                            return;
                                          }
                                          await OrderProvider().checkoutOrder(
                                            adresa: adresa,
                                            grad: grad,
                                            postanskiBroj: postanskiBroj,
                                            nacinPlacanja: nacinPlacanja,
                                          );
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Narudžba zaprimljena!",
                                                ),
                                              ),
                                            );
                                            await _loadCart();
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e.toString().replaceFirst(
                                                  "Exception: ",
                                                  "",
                                                ),
                                              ),
                                            ),
                                          );
                                        } finally {
                                          if (mounted) setState(() {});
                                        }
                                      },
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Color(0xFF233348),
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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

class CheckoutDialog extends StatefulWidget {
  final double totalAmount;
  final String ime;
  final void Function({
    required String adresa,
    required String grad,
    required String postanskiBroj,
    required String nacinPlacanja,
  })
  onKes;
  final void Function({
    required String adresa,
    required String grad,
    required String postanskiBroj,
    required String nacinPlacanja,
  })
  onKartica;

  const CheckoutDialog({
    required this.totalAmount,
    required this.ime,
    required this.onKes,
    required this.onKartica,
    super.key,
  });

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _adresaController = TextEditingController();
  final _gradController = TextEditingController();
  final _postanskiBrojController = TextEditingController();
  String _selectedPayment = "Pouzeće";

  @override
  void dispose() {
    _adresaController.dispose();
    _gradController.dispose();
    _postanskiBrojController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Završi narudžbu",
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF233348)),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${widget.ime}",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF233348),
                  ),
                ),
              ),
              SizedBox(height: 13),
              TextFormField(
                controller: _adresaController,
                decoration: _inputDecoration("Ulica i broj"),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Obavezno polje!" : null,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _gradController,
                      decoration: _inputDecoration("Grad"),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? "Obavezno polje!"
                          : null,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _postanskiBrojController,
                      decoration: _inputDecoration("Poštanski broj"),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Obavezno polje!"
                          : (RegExp(r'^[0-9]{5}$').hasMatch(v.trim())
                                ? null
                                : "Unesite 5 cifara"),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),
              DropdownButtonFormField<String>(
                decoration: _inputDecoration("Način plaćanja"),
                value: _selectedPayment,
                items: [
                  DropdownMenuItem(
                    value: "Pouzeće",
                    child: Text("Pouzeće (gotovina)"),
                  ),
                  DropdownMenuItem(
                    value: "Kartica",
                    child: Text("Kartica (online)"),
                  ),
                ],
                onChanged: (val) =>
                    setState(() => _selectedPayment = val ?? "Pouzeće"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Odaberi način plaćanja!" : null,
              ),
              SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Ukupno:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    "${widget.totalAmount.toStringAsFixed(2)} KM",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Otkaži"),
        ),
        if (_selectedPayment == "Kartica")
          ElevatedButton.icon(
            icon: Icon(Icons.credit_card),
            label: Text("Nastavi na plaćanje"),
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                widget.onKartica(
                  adresa: _adresaController.text.trim(),
                  grad: _gradController.text.trim(),
                  postanskiBroj: _postanskiBrojController.text.trim(),
                  nacinPlacanja: _selectedPayment,
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 13, horizontal: 20),
              textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        if (_selectedPayment == "Pouzeće")
          ElevatedButton.icon(
            icon: Icon(Icons.check),
            label: Text("Završi narudžbu"),
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                widget.onKes(
                  adresa: _adresaController.text.trim(),
                  grad: _gradController.text.trim(),
                  postanskiBroj: _postanskiBrojController.text.trim(),
                  nacinPlacanja: _selectedPayment,
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF233348),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 13, horizontal: 20),
              textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
      ],
    );
  }
}
