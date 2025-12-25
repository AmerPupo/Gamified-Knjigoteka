enum RestockRequestStatus { pending, approved, rejected }

RestockRequestStatus StatusFromInt(int val) {
  switch (val) {
    case 1:
      return RestockRequestStatus.approved;
    case 2:
      return RestockRequestStatus.rejected;
    default:
      return RestockRequestStatus.pending;
  }
}

class RestockRequest {
  final int id;
  final int bookId;
  final String bookTitle;
  final int branchId;
  final String branchName;
  final int employeeId;
  final String employeeName;
  final DateTime requestedAt;
  final int quantityRequested;
  final RestockRequestStatus status;

  RestockRequest({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.branchId,
    required this.branchName,
    required this.employeeId,
    required this.employeeName,
    required this.requestedAt,
    required this.quantityRequested,
    required this.status,
  });

  factory RestockRequest.fromJson(Map<String, dynamic> json) {
    return RestockRequest(
      id: json['id'],
      bookId: json['bookId'],
      bookTitle: json['bookTitle'],
      branchId: json['branchId'],
      branchName: json['branchName'],
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      requestedAt: DateTime.parse(json['requestedAt']),
      quantityRequested: json['quantityRequested'],
      status: StatusFromInt(json['status']),
    );
  }
}
