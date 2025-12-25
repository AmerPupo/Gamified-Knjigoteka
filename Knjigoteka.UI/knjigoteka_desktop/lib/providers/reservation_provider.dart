import 'package:flutter/material.dart';
import 'package:knjigoteka_desktop/main.dart';
import 'package:knjigoteka_desktop/providers/auth_provider.dart';
import '../models/reservation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReservationProvider with ChangeNotifier {
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: 'http://localhost:7295/api',
  );

  Future<List<Reservation>> getAllReservations({
    int? branchId,
    bool sandbox = false,
  }) async {
    final token = AuthProvider.token;

    final queryParams = <String, String>{};

    if (branchId != null) {
      queryParams['BranchId'] = branchId.toString();
    }
    if (sandbox) {
      queryParams['Sandbox'] = 'true';
    }

    String url = '$_baseUrl/Reservations';
    if (queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map(
            (e) =>
                '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
          )
          .join('&');
      url += '?$queryString';
    }

    final res = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Reservations URL: $url');
    print('Reservations body: ${res.body}');

    _ensureValidResponseOrThrow(res);

    final decoded = jsonDecode(res.body);
    final List items = decoded is List ? decoded : decoded['items'] ?? [];
    return items.map((json) => Reservation.fromJson(json)).toList();
  }

  Future<void> deleteReservation(int reservationId) async {
    final token = AuthProvider.token;
    final res = await http.delete(
      Uri.parse('$_baseUrl/Reservations/$reservationId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    _ensureValidResponseOrThrow(res);
    notifyListeners();
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
