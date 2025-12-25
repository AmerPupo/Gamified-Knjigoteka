import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:knjigoteka_mobile/main.dart';
import '../providers/auth_provider.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://10.0.2.2:7295/api",
  );

  final String _endpoint;
  BaseProvider(this._endpoint);

  Map<String, String> getHeaders() {
    final token = AuthProvider.token;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Universal GET (query params iz map-e)
  Future<List<T>> getAll({Map<String, dynamic>? params}) async {
    String url = '$_baseUrl/$_endpoint';
    if (params != null && params.isNotEmpty) {
      url += '?' + Uri(queryParameters: params).query;
    }
    final res = await http.get(Uri.parse(url), headers: getHeaders());
    _ensureValidResponseOrThrow(res);

    final data = jsonDecode(res.body);
    final list = (data['items'] ?? []) as List;
    return list.map((e) => fromJson(e)).toList();
  }

  // GET BY ID
  Future<T> getById(int id) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/$_endpoint/$id'),
      headers: getHeaders(),
    );
    _ensureValidResponseOrThrow(res);
    return fromJson(jsonDecode(res.body));
  }

  // INSERT
  Future<T> insert(dynamic request) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/$_endpoint'),
      headers: getHeaders(),
      body: jsonEncode(request),
    );
    _ensureValidResponseOrThrow(res);
    return fromJson(jsonDecode(res.body));
  }

  // UPDATE
  Future<T> update(int id, dynamic request) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/$_endpoint/$id'),
      headers: getHeaders(),
      body: jsonEncode(request),
    );
    _ensureValidResponseOrThrow(res);
    return fromJson(jsonDecode(res.body));
  }

  // DELETE
  Future<bool> delete(int id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/$_endpoint/$id'),
      headers: getHeaders(),
    );
    _ensureValidResponseOrThrow(res);
    return res.body.toLowerCase().contains("true");
  }

  T fromJson(dynamic data);

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
