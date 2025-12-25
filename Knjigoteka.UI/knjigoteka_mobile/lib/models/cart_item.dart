class CartItem {
  final int bookId;
  final String title;
  final String author;
  final double unitPrice;
  final int quantity;
  final String? photoEndpoint;

  CartItem({
    required this.bookId,
    required this.title,
    required this.author,
    required this.unitPrice,
    required this.quantity,
    this.photoEndpoint,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    bookId: json['bookId'],
    title: json['title'],
    author: json['author'],
    unitPrice: (json['unitPrice'] as num).toDouble(),
    quantity: json['quantity'],
    photoEndpoint: json['photoEndpoint'],
  );
}
