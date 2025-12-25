import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:knjigoteka_mobile/providers/auth_provider.dart';

class OrderProvider with ChangeNotifier {
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://10.0.2.2:7295/api",
  );

  Future<void> checkoutOrder({
    required String adresa,
    required String grad,
    required String postanskiBroj,
    required String nacinPlacanja,
  }) async {
    final token = AuthProvider.token;
    final response = await http.post(
      Uri.parse("$_baseUrl/Order/checkout"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "deliveryAddress": "$adresa, $postanskiBroj $grad",
        "paymentMethod": nacinPlacanja,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      print(response.statusCode);
      print(response.body);
      throw Exception(
        jsonDecode(response.body)["message"] ?? "Greška pri slanju narudžbe.",
      );
    }
  }
}
