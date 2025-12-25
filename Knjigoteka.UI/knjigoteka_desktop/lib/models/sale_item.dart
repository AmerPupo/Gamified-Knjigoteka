class SaleItem {
  final int id;
  final int bookId;
  final String bookTitle;
  final int quantity;
  final double unitPrice;
  SaleItem({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.quantity,
    required this.unitPrice,
  });
  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
    id: json['id'],
    bookId: json['bookId'],
    bookTitle: json['bookTitle'] ?? "",
    quantity: json['quantity'],
    unitPrice: (json['unitPrice'] as num).toDouble(),
  );
}
