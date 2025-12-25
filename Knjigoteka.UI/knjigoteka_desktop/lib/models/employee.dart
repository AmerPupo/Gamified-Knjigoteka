class Employee {
  final int id;
  final int userId;
  final String fullName;
  final int branchId;
  final String branchName;
  final String employmentDate;
  final bool isActive;

  Employee({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.branchId,
    required this.branchName,
    required this.employmentDate,
    required this.isActive,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'],
    userId: json['userId'],
    fullName: json['fullName'],
    branchId: json['branchId'],
    branchName: json['branchName'],
    employmentDate: json['employmentDate'],
    isActive: json['isActive'] ?? true,
  );
}
