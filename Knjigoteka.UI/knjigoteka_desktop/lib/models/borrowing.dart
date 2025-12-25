class Borrowing {
  final int id;
  final int bookId;
  final String bookTitle;
  final int userId;
  final String userName;
  final int branchId;
  final String branchName;
  final int? reservationId;
  final DateTime borrowedAt;
  final DateTime dueDate;
  final DateTime? returnedAt;
  final bool isLate;

  Borrowing({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.userId,
    required this.userName,
    required this.branchId,
    required this.branchName,
    this.reservationId,
    required this.borrowedAt,
    required this.dueDate,
    this.returnedAt,
    required this.isLate,
  });

  factory Borrowing.fromJson(Map<String, dynamic> json) {
    return Borrowing(
      id: json['id'],
      bookId: json['bookId'],
      bookTitle: json['bookTitle'] ?? '',
      userId: json['userId'],
      userName: json['userFullName'] ?? '',
      branchId: json['branchId'],
      branchName: json['branchName'] ?? '',
      reservationId: json['reservationId'],
      borrowedAt: DateTime.parse(json['borrowedAt']),
      dueDate: DateTime.parse(json['dueDate']),
      returnedAt: json['returnedAt'] != null
          ? DateTime.parse(json['returnedAt'])
          : null,
      isLate: json['isLate'] ?? false,
    );
  }
}
