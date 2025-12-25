class Reservation {
  final int id;
  final int userId;
  final String userName;
  final int bookId;
  final String bookTitle;
  final int branchId;
  final String branchName;
  final DateTime reservedAt;
  final DateTime? claimedAt;
  final DateTime? returnedAt;
  final DateTime? expiredAt;
  final String status;

  Reservation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.bookId,
    required this.bookTitle,
    required this.branchId,
    required this.branchName,
    required this.reservedAt,
    this.claimedAt,
    this.returnedAt,
    this.expiredAt,
    required this.status,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'] ?? '',
      bookId: json['bookId'],
      bookTitle: json['bookTitle'] ?? '',
      branchId: json['branchId'],
      branchName: json['branchName'] ?? '',
      reservedAt: DateTime.parse(json['reservedAt']),
      claimedAt: json['claimedAt'] != null
          ? DateTime.parse(json['claimedAt'])
          : null,
      returnedAt: json['returnedAt'] != null
          ? DateTime.parse(json['returnedAt'])
          : null,
      expiredAt: json['expiredAt'] != null
          ? DateTime.parse(json['expiredAt'])
          : null,
      status: json['status'] ?? '',
    );
  }
}
