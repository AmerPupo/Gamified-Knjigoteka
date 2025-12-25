import '../models/order.dart';
import 'base_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderProvider extends BaseProvider<Order> {
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: 'http://localhost:7295/api',
  );
  OrderProvider() : super('Order');

  @override
  Order fromJson(data) => Order.fromJson(data);

  Future<List<Order>> getAllOrders() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/Order'),
      headers: getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  Future<bool> approveOrder(int id) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/Order/$id/approve'),
      headers: getHeaders(),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  Future<bool> rejectOrder(int id) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/Order/$id/reject'),
      headers: getHeaders(),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}
