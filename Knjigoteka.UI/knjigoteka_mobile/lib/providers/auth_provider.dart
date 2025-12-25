import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/login_response.dart';

class AuthProvider extends ChangeNotifier {
  static String? token;
  LoginResponse? _user;

  static bool get isLoggedIn => token != null;

  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://10.0.2.2:7295/api",
  );

  Future<void> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/User/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      token = data['token'];

      final userRes = await http.get(
        Uri.parse('$_baseUrl/User/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        _user = LoginResponse.fromJson(userData);
        notifyListeners();
      } else {
        token = null;
        throw Exception("Failed to fetch user info.");
      }
    } else {
      throw Exception('Pogrešan email ili lozinka.');
    }
  }

  Future<void> logout() async {
    token = null;
    _user = null;
    notifyListeners();
  }

  Future<void> editProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    if (token == null) throw Exception("Not authenticated.");

    final res = await http.post(
      Uri.parse('$_baseUrl/User/edit-profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      token = data['token'];

      final userRes = await http.get(
        Uri.parse('$_baseUrl/User/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        _user = LoginResponse.fromJson(userData);
        notifyListeners();
      } else {
        throw Exception("Failed to refresh user info.");
      }
    } else {
      String msg = "Greška prilikom ažuriranja profila.";
      try {
        msg = jsonDecode(res.body)['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    if (token == null) throw Exception('Niste prijavljeni.');

    final res = await http.post(
      Uri.parse('$_baseUrl/User/change-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );
    print(res.statusCode);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      token = data['token'];
      notifyListeners();
    } else if (res.statusCode == 400 || res.statusCode == 401) {
      throw Exception('Pogrešna stara šifra.');
    } else {
      String errorMsg = 'Došlo je do greške. Pokušajte ponovo.';
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['message'] != null) {
          errorMsg = body['message'];
        } else if (body is String) {
          errorMsg = body;
        }
      } catch (_) {
        errorMsg = res.body;
      }
      throw Exception(errorMsg);
    }
  }

  Future<void> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/User/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      await login(email, password);
    } else {
      String msg = "Greška pri registraciji.";
      try {
        msg = jsonDecode(res.body)['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  String? get role => _user?.role;
  int? get branchId => _user?.branchId;
  int? get userId => _user?.id;
  String? get fullName => _user?.fullName;
  String? get email => _user?.email;
}
