import 'package:knjigoteka_desktop/models/sale_item.dart';

class Sale {
  final int id;
  final int employeeId;
  final String employeeName;
  final int branchId;
  final String branchName;
  final DateTime saleDate;
  final double totalAmount;
  final List<SaleItem> items;
  Sale({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.branchId,
    required this.branchName,
    required this.saleDate,
    required this.totalAmount,
    required this.items,
  });
  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
    id: json['id'],
    employeeId: json['employeeId'],
    employeeName: json['employeeName'] ?? "",
    branchId: json['branchId'],
    branchName: json['branchName'] ?? "",
    saleDate: DateTime.parse(json['saleDate']),
    totalAmount: (json['totalAmount'] as num).toDouble(),
    items: (json['items'] as List).map((e) => SaleItem.fromJson(e)).toList(),
  );
}
