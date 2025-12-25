class SaleInsert {
  final int employeeId;
  final List<SaleItemInsert> items;
  final int branchId;
  SaleInsert({
    required this.employeeId,
    required this.items,
    required this.branchId,
  });
  Map<String, dynamic> toJson() => {
    "EmployeeId": employeeId,
    "Items": items.map((i) => i.toJson()).toList(),
    "BranchId": branchId,
  };
}

class SaleItemInsert {
  final int bookId;
  final int quantity;
  SaleItemInsert({required this.bookId, required this.quantity});
  Map<String, dynamic> toJson() => {"BookId": bookId, "Quantity": quantity};
}
