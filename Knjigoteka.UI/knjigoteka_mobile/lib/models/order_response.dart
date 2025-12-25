class OrderResponse {
  final int id;
  final DateTime createdAt;
  final String status;
  final double totalAmount;
  final List<OrderItem> items;

  OrderResponse({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.totalAmount,
    required this.items,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'] is String
          ? json['status']
          : _orderStatusToString(json['status']),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      items: (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
    );
  }
}

String _orderStatusToString(dynamic val) {
  switch (val) {
    case 0:
      return 'Pending';
    case 1:
      return 'Approved';
    case 2:
      return 'Rejected';
    default:
      return 'Unknown';
  }
}

class OrderItem {
  final int bookId;
  final String title;
  final String? author;
  final int quantity;
  final double unitPrice;
  final String? photoEndpoint;

  OrderItem({
    required this.bookId,
    required this.title,
    this.author,
    required this.quantity,
    required this.unitPrice,
    this.photoEndpoint,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      bookId: json['bookId'],
      title: json['title'],
      author: json['author'],
      quantity: json['quantity'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
      photoEndpoint: json['photoEndpoint'],
    );
  }
}
