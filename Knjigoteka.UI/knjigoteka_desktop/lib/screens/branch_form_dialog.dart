import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import '../models/branch.dart';
import '../models/city.dart';

class BranchFormDialog extends StatefulWidget {
  final Branch? branch;
  final List<City> cities;
  final void Function(Branch branch) onSaved;

  const BranchFormDialog({
    this.branch,
    required this.cities,
    required this.onSaved,
  });

  @override
  _BranchFormDialogState createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends State<BranchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _openTimeController;
  late TextEditingController _closeTimeController;
  int? _cityId;

  @override
  void initState() {
    super.initState();
    final b = widget.branch;
    _nameController = TextEditingController(text: b?.name ?? "");
    _addressController = TextEditingController(text: b?.address ?? "");
    _phoneController = TextEditingController(text: b?.phoneNumber ?? "");
    _openTimeController = TextEditingController(text: b?.openingTime ?? "");
    _closeTimeController = TextEditingController(text: b?.closingTime ?? "");
    _cityId =
        b?.cityId ?? (widget.cities.isNotEmpty ? widget.cities.first.id : null);
  }

  // Validacija telefona: mora biti validan broj (BH format: +387xxxxxxx)
  String? _validatePhone(String? val) {
    if (val == null || val.isEmpty) return "Obavezno polje";
    final pattern = r"^(\+?\d{7,15})$";
    if (!RegExp(pattern).hasMatch(val.replaceAll(' ', ''))) {
      return "Neispravan format broja telefona";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Responsive širina
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
                        widget.branch == null
                            ? "Dodaj poslovnicu"
                            : "Uredi poslovnicu",
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
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: "Naziv"),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Obavezno polje" : null,
                ),
                SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: "Adresa"),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Obavezno polje" : null,
                ),
                SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: _cityId,
                  items: widget.cities
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _cityId = val),
                  decoration: InputDecoration(labelText: "Grad"),
                  validator: (val) =>
                      val == null ? "Obavezno odabrati grad" : null,
                ),
                SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: "Telefon"),
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                  inputFormatters: [
                    PhoneInputFormatter(defaultCountryCode: 'BA'),
                  ],
                ),
                SizedBox(height: 14),
                TextFormField(
                  controller: _openTimeController,
                  decoration: InputDecoration(
                    labelText: "Vrijeme otvaranja (npr. 08:00:00)",
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Obavezno polje" : null,
                ),
                SizedBox(height: 14),
                TextFormField(
                  controller: _closeTimeController,
                  decoration: InputDecoration(
                    labelText: "Vrijeme zatvaranja (npr. 20:00:00)",
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Obavezno polje" : null,
                ),
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
                        if (_formKey.currentState?.validate() != true) return;
                        final branch = Branch(
                          id: widget.branch?.id ?? 0,
                          name: _nameController.text,
                          address: _addressController.text,
                          cityId: _cityId!,
                          cityName: widget.cities
                              .firstWhere((c) => c.id == _cityId)
                              .name,
                          phoneNumber: _phoneController.text,
                          openingTime: _openTimeController.text,
                          closingTime: _closeTimeController.text,
                        );
                        widget.onSaved(branch);
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
