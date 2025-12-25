import 'package:flutter/material.dart';
import 'package:knjigoteka_desktop/providers/branch_provider.dart';
import 'package:knjigoteka_desktop/providers/user_provider.dart';
import 'package:knjigoteka_desktop/screens/employee_form_dialog.dart';
import 'package:provider/provider.dart';
import '../providers/employee_provider.dart';
import '../models/employee.dart';

class EmployeesScreen extends StatefulWidget {
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  String _search = "";
  bool _loading = true;
  String? _error;
  List<Employee> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      final results = await provider.searchEmployees(nameFTS: _search);
      setState(() => _employees = results);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  void _onSearchChanged(String value) {
    setState(() => _search = value);
    _loadEmployees();
  }

  void _editEmployee(Employee employee) async {
    final branches = await Provider.of<BranchProvider>(
      context,
      listen: false,
    ).getAll();
    showDialog(
      context: context,
      builder: (ctx) => EmployeeFormDialog(
        employee: employee,
        branches: branches,
        users: const [],
        onSaved: (branchId, _) async {
          await Provider.of<EmployeeProvider>(
            context,
            listen: false,
          ).update(employee.id, {'branchId': branchId});
          _loadEmployees();
        },
      ),
    );
  }

  void _addEmployee() async {
    final branches = await Provider.of<BranchProvider>(
      context,
      listen: false,
    ).getAll();
    final users = await Provider.of<UserProvider>(
      context,
      listen: false,
    ).getUsersForEmployee();

    showDialog(
      context: context,
      builder: (ctx) => EmployeeFormDialog(
        branches: branches,
        users: users,
        onSaved: (branchId, userId) async {
          await Provider.of<EmployeeProvider>(
            context,
            listen: false,
          ).insert({'userId': userId, 'branchId': branchId});
          _loadEmployees();
        },
      ),
    );
  }

  void _deleteEmployee(Employee employee) async {
    final provider = Provider.of<EmployeeProvider>(context, listen: false);
    final confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text("Brisanje uposlenika")),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        content: Text(
          "Da li ste sigurni da želite obrisati uposlenika '${employee.fullName}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Odustani"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text("Obriši"),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await provider.delete(employee.id);
        _loadEmployees();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Uposlenik obrisan.")));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Greška pri brisanju: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = (screenWidth ~/ 650).clamp(1, 3); // Responsive

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Uposlenici',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Pretraži uposlenike po imenu',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _addEmployee,
                icon: Icon(Icons.add),
                label: Text("Dodaj novog"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF233348),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
          if (_loading)
            Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Text(_error!, style: TextStyle(color: Colors.red)),
              ),
            )
          else if (_employees.isEmpty)
            Expanded(child: Center(child: Text("Nema uposlenika.")))
          else
            Expanded(
              child: GridView.builder(
                itemCount: _employees.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  childAspectRatio: 2.7,
                ),
                itemBuilder: (ctx, i) {
                  final e = _employees[i];
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black12, width: 1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Podaci
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.fullName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Filijala: ${e.branchName}",
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                "Datum zaposlenja: ${e.employmentDate.toString().substring(0, 10)}",
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        // Akcije
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 110,
                              child: ElevatedButton(
                                onPressed: () => _editEmployee(e),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF233348),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text("Uredi"),
                              ),
                            ),
                            SizedBox(height: 10),
                            SizedBox(
                              width: 110,
                              child: ElevatedButton(
                                onPressed: () => _deleteEmployee(e),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text("Obriši"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
