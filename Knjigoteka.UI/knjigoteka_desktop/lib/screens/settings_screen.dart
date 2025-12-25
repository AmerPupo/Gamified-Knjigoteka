import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _editMode = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ime;
  late TextEditingController _prezime;
  late TextEditingController _email;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _ime = TextEditingController(text: auth.fullName?.split(' ').first ?? '');
    _prezime = TextEditingController(
      text: auth.fullName?.split(' ').last ?? '',
    );
    _email = TextEditingController(text: auth.email ?? '');
  }

  @override
  void dispose() {
    _ime.dispose();
    _prezime.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xfff7f9fb),
      appBar: AppBar(
        backgroundColor: const Color(0xfff7f9fb),
        elevation: 0,
        toolbarHeight: 100,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Postavke računa',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF233348),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: 24, left: 48, right: 48),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 34, horizontal: 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Podaci o korisniku",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF233348),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => ChangePasswordDialog(),
                          );
                        },
                        icon: Icon(Icons.lock_outline, size: 20),
                        label: Text("Promijeni šifru"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF233348),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          textStyle: TextStyle(fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                      SizedBox(width: 18),
                      !_editMode
                          ? ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _editMode = true;
                                  _ime.text =
                                      auth.fullName?.split(' ').first ?? '';
                                  _prezime.text =
                                      auth.fullName?.split(' ').last ?? '';
                                  _email.text = auth.email ?? '';
                                  _error = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF233348),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 26,
                                  vertical: 13,
                                ),
                                textStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              child: Text("Uredi"),
                            )
                          : Container(),
                    ],
                  ),
                  SizedBox(height: 22),
                  _editMode
                      ? Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _ime,
                                decoration: InputDecoration(
                                  labelText: "Ime",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                                validator: (v) =>
                                    v!.isEmpty ? "Obavezno polje" : null,
                              ),
                              SizedBox(height: 12),
                              TextFormField(
                                controller: _prezime,
                                decoration: InputDecoration(
                                  labelText: "Prezime",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                                validator: (v) =>
                                    v!.isEmpty ? "Obavezno polje" : null,
                              ),
                              SizedBox(height: 12),
                              TextFormField(
                                controller: _email,
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return "Obavezno polje";
                                  final emailRegex = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  );
                                  if (!emailRegex.hasMatch(value)) {
                                    return "Email nije ispravan format";
                                  }
                                  return null;
                                },
                              ),
                              if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _error!,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              SizedBox(height: 22),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: _saveProfile,
                                    child: Text("Sačuvaj"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF233348),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 30,
                                        vertical: 14,
                                      ),
                                      textStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _editMode = false;
                                        _error = null;
                                      });
                                    },
                                    child: Text("Odustani"),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 30,
                                        vertical: 14,
                                      ),
                                      textStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDataRow(
                              "Ime",
                              auth.fullName?.split(' ').first ?? '-',
                            ),
                            SizedBox(height: 12),
                            _buildDataRow(
                              "Prezime",
                              auth.fullName?.split(' ').last ?? '-',
                            ),
                            SizedBox(height: 12),
                            _buildDataRow("Email", auth.email ?? '-'),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 11, horizontal: 20),
            decoration: BoxDecoration(
              color: Color(0xfff7f9fb),
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Color(0xFF233348)),
            ),
          ),
        ),
      ],
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.editProfile(
        firstName: _ime.text.trim(),
        lastName: _prezime.text.trim(),
        email: _email.text.trim(),
      );
      setState(() => _editMode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Podaci su uspješno ažurirani!"),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

class ChangePasswordDialog extends StatefulWidget {
  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;
  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxWidth: 420),
        padding: EdgeInsets.symmetric(vertical: 36, horizontal: 38),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Promjena šifre",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF233348),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: 22),
              TextFormField(
                controller: _oldPassword,
                obscureText: !_showOld,
                decoration: InputDecoration(
                  labelText: "Stara šifra",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showOld ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _showOld = !_showOld),
                  ),
                ),
                validator: (v) {
                  if (v!.isEmpty) return "Unesi staru šifru";
                  if (_error != null &&
                      _error.toString().contains("stara šifra"))
                    return "Pogrešna stara šifra";
                  return null;
                },
              ),
              SizedBox(height: 18),
              TextFormField(
                controller: _newPassword,
                obscureText: !_showNew,
                decoration: InputDecoration(
                  labelText: "Nova šifra",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showNew ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _showNew = !_showNew),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Unesi novu šifru";
                  if (v.length < 8)
                    return "Šifra mora imati najmanje 8 znakova";
                  if (!RegExp(r'[A-Z]').hasMatch(v))
                    return "Šifra mora sadržavati bar jedno veliko slovo";
                  if (!RegExp(r'[a-z]').hasMatch(v))
                    return "Šifra mora sadržavati bar jedno malo slovo";
                  if (!RegExp(r'[0-9]').hasMatch(v))
                    return "Šifra mora sadržavati bar jedan broj";
                  if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(v))
                    return "Šifra mora sadržavati bar jedan specijalni znak";
                  return null;
                },
              ),
              SizedBox(height: 18),
              TextFormField(
                controller: _confirmPassword,
                obscureText: !_showConfirm,
                decoration: InputDecoration(
                  labelText: "Potvrdi novu šifru",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _showConfirm = !_showConfirm),
                  ),
                ),
                validator: (v) =>
                    v != _newPassword.text ? "Šifre se ne podudaraju" : null,
              ),
              if (_success != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    _success!,
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ),
              SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF233348),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  onPressed: _loading ? null : _changePassword,
                  child: _loading
                      ? SizedBox(
                          height: 21,
                          width: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          "Promijeni šifru",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).changePassword(_oldPassword.text, _newPassword.text);

      setState(() {
        _success = "Šifra je uspješno promijenjena!";
        _error = null;
      });

      await Future.delayed(Duration(milliseconds: 1200));
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Šifra promijenjena."),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _success = null;
      });
    } finally {
      setState(() => _loading = false);
    }
  }
}
