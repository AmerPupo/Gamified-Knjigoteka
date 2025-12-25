import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:knjigoteka_mobile/models/cart_item.dart';
import 'package:knjigoteka_mobile/models/cart_response.dart';
import 'package:knjigoteka_mobile/providers/auth_provider.dart';

class CartProvider with ChangeNotifier {
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://10.0.2.2:7295/api",
  );

  CartResponse? _cart;

  CartResponse? get cart => _cart;

  int get totalQuantity =>
      _cart?.items.fold<int>(0, (prev, item) => prev + (item.quantity)) ?? 0;

  Future<void> loadCart() async {
    final token = AuthProvider.token;
    final response = await http.get(
      Uri.parse("$_baseUrl/Cart"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _cart = CartResponse.fromJson(data);
      notifyListeners();
    } else {
      throw Exception("Greška prilikom dohvata korpe");
    }
  }

  Future<CartResponse> getCart() async {
    final token = AuthProvider.token;
    final response = await http.get(
      Uri.parse("$_baseUrl/Cart"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode == 200) {
      return CartResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Greška pri dohvatu korpe");
    }
  }

  Future<void> upsertCartItem({
    required int bookId,
    required int quantity,
  }) async {
    final token = AuthProvider.token;
    final response = await http.post(
      Uri.parse("$_baseUrl/Cart"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode({"BookId": bookId, "Quantity": quantity}),
    );
    if (response.statusCode != 200) {
      throw Exception(
        jsonDecode(response.body)["message"] ?? "Greška pri dodavanju u korpu.",
      );
    }
    await loadCart();
  }

  Future<int> getBookQuantity(int bookId) async {
    await loadCart();
    return _cart?.items
            .firstWhere(
              (e) => e.bookId == bookId,
              orElse: () => CartItem(
                bookId: bookId,
                quantity: 0,
                title: '',
                author: '',
                unitPrice: 0.0,
              ),
            )
            .quantity ??
        0;
  }
}
