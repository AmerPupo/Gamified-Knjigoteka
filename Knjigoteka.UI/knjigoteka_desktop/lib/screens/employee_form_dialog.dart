import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../models/branch.dart';
import '../models/user.dart';

class EmployeeFormDialog extends StatefulWidget {
  final Employee? employee;
  final List<Branch> branches;
  final List<User> users;
  final void Function(int branchId, int userId) onSaved;

  const EmployeeFormDialog({
    this.employee,
    required this.branches,
    required this.users,
    required this.onSaved,
  });

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  int? _branchId;
  User? _selectedUser;
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _branchId =
        widget.employee?.branchId ??
        (widget.branches.isNotEmpty ? widget.branches.first.id : null);

    if (widget.employee != null) {
      _selectedUser = User(
        id: widget.employee!.userId,
        fullName: widget.employee!.fullName,
        email: '',
      );
      _userController.text = _selectedUser!.fullName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.employee != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 500
        ? screenWidth * 0.96
        : screenWidth < 900
        ? 400.0
        : 480.0;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.employee == null
                            ? "Dodaj uposlenika"
                            : "Uredi uposlenika",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                if (!isEdit)
                  Column(
                    children: [
                      RawAutocomplete<User>(
                        textEditingController: _userController,
                        focusNode: FocusNode(),
                        optionsBuilder: (TextEditingValue value) {
                          if (value.text.isEmpty)
                            return const Iterable<User>.empty();
                          final input = value.text.toLowerCase();
                          return widget.users.where(
                            (u) =>
                                u.fullName.toLowerCase().contains(input) ||
                                u.email.toLowerCase().contains(input),
                          );
                        },
                        displayStringForOption: (user) =>
                            '${user.fullName} <${user.email}>',
                        onSelected: (user) {
                          _selectedUser = user;
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Korisnik (ime ili email)',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) => _selectedUser == null
                                    ? 'Odaberi korisnika'
                                    : null,
                                onChanged: (_) {
                                  if (_userController.text.isEmpty)
                                    _selectedUser = null;
                                },
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              child: SizedBox(
                                width: 400,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final User option = options.elementAt(
                                      index,
                                    );
                                    return ListTile(
                                      title: Text(option.fullName),
                                      subtitle: Text(option.email),
                                      onTap: () {
                                        onSelected(option);
                                        _userController.text =
                                            '${option.fullName} <${option.email}>';
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                DropdownButtonFormField<int>(
                  value: _branchId,
                  items: widget.branches
                      .map(
                        (b) =>
                            DropdownMenuItem(value: b.id, child: Text(b.name)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _branchId = val),
                  decoration: InputDecoration(labelText: "Filijala"),
                  validator: (val) =>
                      val == null ? "Obavezno odabrati filijalu" : null,
                ),
                if (isEdit) ...[
                  SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        "Korisnik: ",
                        style: TextStyle(color: Colors.black54),
                      ),
                      Text(
                        widget.employee!.fullName,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        "Datum zaposlenja: ",
                        style: TextStyle(color: Colors.black54),
                      ),
                      Text(widget.employee!.employmentDate.substring(0, 10)),
                    ],
                  ),
                ],
                SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Otkaži"),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        if (_branchId == null ||
                            (!isEdit && _selectedUser == null))
                          return;
                        widget.onSaved(
                          _branchId!,
                          isEdit ? widget.employee!.userId : _selectedUser!.id,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        textStyle: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: Text("Sačuvaj"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
