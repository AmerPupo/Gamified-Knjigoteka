import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order_response.dart';
import '../models/borrowing_response.dart';

class HistoryProvider with ChangeNotifier {
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://10.0.2.2:7295/api",
  );

  Future<List<OrderResponse>> getMyOrders(String token) async {
    final resp = await http.get(
      Uri.parse("$_baseUrl/Order/mine"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (resp.statusCode == 200) {
      final List data = jsonDecode(resp.body);
      return data.map((e) => OrderResponse.fromJson(e)).toList();
    }
    throw Exception("Ne mogu dohvatiti kupovine");
  }

  Future<List<BorrowingResponse>> getMyBorrowings(String token) async {
    final resp = await http.get(
      Uri.parse("$_baseUrl/Borrowings/mine"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (resp.statusCode == 200) {
      final List data = jsonDecode(resp.body);
      return data.map((e) => BorrowingResponse.fromJson(e)).toList();
    }
    throw Exception("Ne mogu dohvatiti posudbe");
  }
}
