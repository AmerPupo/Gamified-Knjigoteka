import 'cart_item.dart';

class CartResponse {
  final List<CartItem> items;

  CartResponse({required this.items});

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    return CartResponse(
      items: itemsList.map((e) => CartItem.fromJson(e)).toList(),
    );
  }
}
