class ReviewResponse {
  final int id;
  final int bookId;
  final String bookTitle;
  final int userId;
  final String userFullName;
  final int rating;
  final DateTime createdAt;

  ReviewResponse({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.userId,
    required this.userFullName,
    required this.rating,
    required this.createdAt,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) => ReviewResponse(
    id: json['id'],
    bookId: json['bookId'],
    bookTitle: json['bookTitle'],
    userId: json['userId'],
    userFullName: json['userFullName'],
    rating: json['rating'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}
