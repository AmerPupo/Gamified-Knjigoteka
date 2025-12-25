import 'package:flutter/material.dart';
import 'package:knjigoteka_desktop/main.dart';
import 'package:knjigoteka_desktop/providers/auth_provider.dart';
import '../models/borrowing.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BorrowingProvider with ChangeNotifier {
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: 'http://localhost:7295/api',
  );

  Future<List<Borrowing>> getAllBorrowings(
    int branchId, {
    bool sandbox = false,
  }) async {
    final token = AuthProvider.token;
    String url = '$_baseUrl/Borrowings/branch/$branchId';
    if (sandbox) {
      url += '?sandbox=true';
    }
    print("GET URL: $url");
    final res = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
    _ensureValidResponseOrThrow(res);
    final List<dynamic> data = jsonDecode(res.body);
    return data.map((json) => Borrowing.fromJson(json)).toList();
  }

  Future<void> setReturned(int borrowingId, bool returned) async {
    if (!returned) return;
    final token = AuthProvider.token;
    final res = await http.post(
      Uri.parse('$_baseUrl/Borrowings/$borrowingId/return'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _ensureValidResponseOrThrow(res);
    notifyListeners();
  }

  Future<void> deleteBorrowing(int borrowingId) async {
    final token = AuthProvider.token;
    final res = await http.delete(
      Uri.parse('$_baseUrl/Borrowings/$borrowingId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _ensureValidResponseOrThrow(res);
    notifyListeners();
  }

  Future<Borrowing> insert(Map<String, dynamic> data) async {
    final token = AuthProvider.token;
    final res = await http.post(
      Uri.parse('$_baseUrl/Borrowings'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'bookId': data['bookId'],
        'userId': data['userId'],
        'reservationId': data['reservationId'],
      }),
    );
    _ensureValidResponseOrThrow(res);
    return Borrowing.fromJson(jsonDecode(res.body));
  }

  void _ensureValidResponseOrThrow(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    if (res.statusCode == 401) {
      AuthProvider().logout();
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);

      throw Exception("Session expired. Please login again.");
    }

    String msg = res.body;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['message'] != null) {
        msg = decoded['message'];
      }
    } catch (_) {}
    throw Exception("Error ${res.statusCode}: $msg");
  }
}
