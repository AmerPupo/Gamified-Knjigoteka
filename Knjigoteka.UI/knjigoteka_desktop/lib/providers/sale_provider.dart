import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class SaleProvider with ChangeNotifier {
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: 'http://localhost:7295/api',
  );
  Future<void> createSale(Map<String, dynamic> data) async {
    final token = AuthProvider.token;
    final res = await http.post(
      Uri.parse('$_baseUrl/Sale'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      print("Greška pri finaliziranju prodaje: ${res.body}");
      throw Exception("Greška pri finaliziranju prodaje: ${res.body}");
    }
  }
}
