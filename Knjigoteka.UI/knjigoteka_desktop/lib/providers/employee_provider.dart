import '../models/employee.dart';
import 'base_provider.dart';

class EmployeeProvider extends BaseProvider<Employee> {
  EmployeeProvider() : super('Employee');

  @override
  Employee fromJson(data) => Employee.fromJson(data);

  Future<List<Employee>> searchEmployees({
    String? nameFTS,
    int? branchId,
  }) async {
    final params = <String, dynamic>{};
    if (nameFTS != null && nameFTS.isNotEmpty) params['nameFTS'] = nameFTS;
    if (branchId != null) params['branchId'] = branchId;
    return getAll(params: params);
  }
}
