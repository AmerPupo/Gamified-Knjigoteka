import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/branch_inventory.dart';
import '../providers/auth_provider.dart';

class BranchInventoryProvider with ChangeNotifier {
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: 'http://localhost:7295/api',
  );

  Future<List<BranchInventory>> getAvailableForSale(
    int branchId, {
    String fts = "",
    bool sandbox = false,
  }) async {
    print(
      "uslo u getAvailableForSale sa branchId=$branchId, fts='$fts', sandbox=$sandbox",
    );
    String url = '$_baseUrl/branches/inventory?BranchId=$branchId';
    if (fts.isNotEmpty) url += "&FTS=$fts";
    if (sandbox) url += "&sandbox=true";

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
    print('DEBUG body: ${res.body}');
    print('DEBUG decoded runtimeType: ${data.runtimeType}');
    print(
      'DEBUG data["items"] runtimeType: ${data is Map ? data["items"]?.runtimeType : "no map"}',
    );
    final List items = data['items'] ?? [];
    return items
        .map((e) => BranchInventory.fromJson(e))
        .where((b) => b.quantityForSale > 0)
        .toList();
  }

  Future<List<BranchInventory>> getAvailableForBranch(
    int branchId, {
    String fts = "",
    bool sandbox = false,
  }) async {
    String url = '$_baseUrl/branches/inventory?BranchId=$branchId';
    if (fts.isNotEmpty) url += "&FTS=$fts";
    if (sandbox) url += "&sandbox=true";
    final res = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (AuthProvider.token != null && AuthProvider.token!.isNotEmpty)
          'Authorization': 'Bearer ${AuthProvider.token}',
      },
    );
    if (res.statusCode != 200) throw Exception(res.body);
    final data = jsonDecode(res.body);
    final List items = data['items'] ?? [];
    return items.map((e) => BranchInventory.fromJson(e)).toList();
  }

  Future<void> upsertInventory(
    int branchId,
    int bookId,
    int forSale,
    int forBorrow, {
    bool sandbox = false,
  }) async {
    String url = '$_baseUrl/branches/inventory?branchId=$branchId';
    if (sandbox) url += "&sandbox=true";
    final body = jsonEncode({
      "bookId": bookId,
      "supportsBorrowing": forBorrow > 0,
      "quantityForBorrow": forBorrow,
      "quantityForSale": forSale,
    });
    final res = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (AuthProvider.token != null && AuthProvider.token!.isNotEmpty)
          'Authorization': 'Bearer ${AuthProvider.token}',
      },
      body: body,
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
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

  Future<void> removeBookFromBranch(
    int branchId,
    int bookId, {
    bool sandbox = false,
  }) async {
    String url = '$_baseUrl/branches/inventory/$bookId?branchId=$branchId';
    if (sandbox) url += "&sandbox=true";
    final res = await http.delete(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (AuthProvider.token != null && AuthProvider.token!.isNotEmpty)
          'Authorization': 'Bearer ${AuthProvider.token}',
      },
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(res.body);
    }
  }

  Future<List<BranchInventory>> getAvailabilityByBookId(
    int bookId, {
    bool sandbox = false,
  }) async {
    String url = '$_baseUrl/branches/inventory/availability/$bookId';
    if (sandbox) url += "?sandbox=true";
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

  Future<List<BranchInventory>> getAvailableForBorrow(
    int branchId, {
    String fts = "",
    bool sandbox = false,
  }) async {
    String url =
        '$_baseUrl/branches/inventory?BranchId=$branchId&SupportsBorrowing=true';
    if (fts.isNotEmpty) url += "&FTS=$fts";
    if (sandbox) url += "&sandbox=true";
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
    final List items = data['items'] ?? [];
    return items
        .map((e) => BranchInventory.fromJson(e))
        .where((b) => b.supportsBorrowing == true && b.quantityForBorrow > 0)
        .toList();
  }
}
