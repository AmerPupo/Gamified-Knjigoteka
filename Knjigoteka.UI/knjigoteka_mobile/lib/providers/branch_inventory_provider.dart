import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/branch_inventory.dart';
import '../providers/auth_provider.dart';

class BranchInventoryProvider with ChangeNotifier {
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://10.0.2.2:7295/api",
  );

  Future<List<BranchInventory>> getAvailabilityByBookId(int bookId) async {
    String url = '$_baseUrl/branches/inventory/availability/$bookId';
    final res = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (AuthProvider.token != null && AuthProvider.token!.isNotEmpty)
          'Authorization': 'Bearer ${AuthProvider.token}',
      },
    );
    if (res.statusCode != 200) throw Exception("Greška: ${res.body}");
    final data = jsonDecode(res.body);
    final List items = data is List ? data : (data['items'] ?? []);
    return items.map((e) => BranchInventory.fromJson(e)).toList();
  }
}
