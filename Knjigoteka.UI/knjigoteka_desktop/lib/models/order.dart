import 'order_item.dart';

enum OrderStatus { pending, approved, shipped, canceled, delivered, rejected }

OrderStatus orderStatusFromInt(int value) {
  switch (value) {
    case 0:
      return OrderStatus.pending;
    case 1:
      return OrderStatus.approved;
    case 2:
      return OrderStatus.shipped;
    case 3:
      return OrderStatus.canceled;
    case 4:
      return OrderStatus.delivered;
    case 5:
      return OrderStatus.rejected;
    default:
      return OrderStatus.pending;
  }
}

class Order {
  final int id;
  final DateTime createdAt;
  final String userName;
  final OrderStatus status;
  final double totalAmount;
  final String paymentMethod;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.createdAt,
    required this.userName,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    print(json);
    return Order(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      userName: json['userName'],
      status: orderStatusFromInt(
        json['status'] is int
            ? json['status']
            : int.parse(json['status'].toString()),
      ),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'],
      items: (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
    );
  }
}
