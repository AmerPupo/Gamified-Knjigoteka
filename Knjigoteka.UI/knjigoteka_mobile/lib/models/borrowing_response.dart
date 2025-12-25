class BorrowingResponse {
  final int id;
  final int bookId;
  final String title;
  final String? author;
  final DateTime borrowedAt;
  final DateTime dueDate;
  final DateTime? returnedAt;
  final String? photoEndpoint;

  BorrowingResponse({
    required this.id,
    required this.bookId,
    required this.title,
    this.author,
    required this.borrowedAt,
    required this.dueDate,
    this.returnedAt,
    this.photoEndpoint,
  });

  factory BorrowingResponse.fromJson(Map<String, dynamic> json) {
    return BorrowingResponse(
      id: json['id'],
      bookId: json['bookId'],
      title: json['bookTitle'] ?? '',
      author: json['author'], // može biti null
      borrowedAt: DateTime.parse(json['borrowedAt']),
      dueDate: DateTime.parse(json['dueDate']),
      returnedAt: json['returnedAt'] != null && json['returnedAt'] != ""
          ? DateTime.parse(json['returnedAt'])
          : null,
      photoEndpoint: json['photoEndpoint'],
    );
  }
}
