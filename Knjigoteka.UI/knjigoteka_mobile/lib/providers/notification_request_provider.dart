import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotificationRequestProvider with ChangeNotifier {
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://10.0.2.2:7295/api",
  );

  Future<void> createNotificationRequest({
    required int bookId,
    required int branchId,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse("$_baseUrl/NotificationRequest"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'bookId': bookId, 'branchId': branchId}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      String msg;
      try {
        msg = jsonDecode(res.body)['message'] ?? res.body.toString();
      } catch (e) {
        msg = res.body.toString();
      }
      throw Exception(msg);
    }
  }
}
