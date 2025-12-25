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
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Postavke"),
        backgroundColor: Color(0xFF233348),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(18),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Korisnički podaci",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF233348),
                          ),
                        ),
                      ),
                      !_editMode
                          ? IconButton(
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
                              icon: Icon(Icons.edit),
                              color: Color(0xFF233348),
                              tooltip: "Uredi podatke",
                            )
                          : SizedBox.shrink(),
                    ],
                  ),
                  SizedBox(height: 14),
                  _editMode
                      ? Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextField(_ime, "Ime"),
                              SizedBox(height: 9),
                              _buildTextField(_prezime, "Prezime"),
                              SizedBox(height: 9),
                              _buildTextField(_email, "Email", isEmail: true),
                              if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 7.0),
                                  child: Text(
                                    _error!,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              SizedBox(height: 19),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: _saveProfile,
                                    child: Text("Sačuvaj"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF233348),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 14),
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _editMode = false;
                                        _error = null;
                                      });
                                    },
                                    child: Text("Odustani"),
                                    style: OutlinedButton.styleFrom(
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
                            SizedBox(height: 7),
                            _buildDataRow(
                              "Prezime",
                              auth.fullName?.split(' ').last ?? '-',
                            ),
                            SizedBox(height: 7),
                            _buildDataRow("Email", auth.email ?? '-'),
                            SizedBox(height: 18),
                            ElevatedButton.icon(
                              icon: Icon(Icons.lock_reset_rounded, size: 22),
                              label: Text(
                                "Promijeni šifru",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[700],
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 47),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                elevation: 2,
                                shadowColor: Colors.orange,
                              ),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                  builder: (context) => ChangePasswordDialog(),
                                );
                              },
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),

          SizedBox(height: 28),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            child: ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.red[600]),
              title: Text(
                "Odjavi se",
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red[600]),
                        SizedBox(width: 10),
                        Text("Potvrda odjave"),
                      ],
                    ),
                    content: Text(
                      "Jeste li sigurni da se želite odjaviti?",
                      style: TextStyle(fontSize: 15),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text("Otkaži"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text("Odjavi se"),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).logout();
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isEmail = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      ),
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return "Obavezno polje";
        if (isEmail) {
          final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
          if (!emailRegex.hasMatch(v)) return "Email nije ispravan";
        }
        return null;
      },
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
              fontSize: 15,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Color(0xfff7f9fb),
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(fontSize: 15, color: Color(0xFF233348)),
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 15,
          left: 18,
          right: 18,
          top: 20,
        ),
        child: Form(
          key: _formKey,
          child: Wrap(
            runSpacing: 14,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Promjena šifre",
                      style: TextStyle(
                        fontSize: 19,
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
                  if (v.length < 8) return "Min 8 znakova";
                  if (!RegExp(r'[A-Z]').hasMatch(v)) return "Mora veliko slovo";
                  if (!RegExp(r'[a-z]').hasMatch(v)) return "Mora malo slovo";
                  if (!RegExp(r'[0-9]').hasMatch(v)) return "Mora broj";
                  if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(v))
                    return "Mora specijalni znak";
                  return null;
                },
              ),
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
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(_error!, style: TextStyle(color: Colors.red)),
                ),
              if (_success != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _success!,
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF233348),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  onPressed: _loading ? null : _changePassword,
                  child: _loading
                      ? SizedBox(
                          height: 19,
                          width: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          "Promijeni šifru",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
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
