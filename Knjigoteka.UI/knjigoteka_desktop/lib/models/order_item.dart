class OrderItem {
  final int bookId;
  final String title;
  final int quantity;
  final double unitPrice;

  OrderItem({
    required this.bookId,
    required this.title,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    bookId: json['bookId'],
    title: json['title'],
    quantity: json['quantity'],
    unitPrice: (json['unitPrice'] as num).toDouble(),
  );
}
