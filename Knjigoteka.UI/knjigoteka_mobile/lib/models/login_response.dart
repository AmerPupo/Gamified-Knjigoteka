class LoginResponse {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final int? branchId;
  LoginResponse({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.branchId,
  });
  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    id: json['id'],
    fullName: json['fullName'],
    email: json['email'],
    role: json['role'],
    branchId: json['branchId'],
  );
}
