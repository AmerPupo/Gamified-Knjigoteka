import 'package:flutter/material.dart';
import 'package:knjigoteka_mobile/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _passwordError;
  String? _formError;
  bool loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _emailError = null;
      _passwordError = null;
      _formError = null;
    });

    bool valid = true;

    if (!isLogin) {
      if (_firstNameController.text.trim().isEmpty) {
        _firstNameError = "Unesi ime";
        valid = false;
      }
      if (_lastNameController.text.trim().isEmpty) {
        _lastNameError = "Unesi prezime";
        valid = false;
      }
      if (_emailController.text.trim().isEmpty) {
        _emailError = "Unesi email";
        valid = false;
      } else if (!RegExp(
        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
      ).hasMatch(_emailController.text.trim())) {
        _emailError = "Email nije ispravan format";
        valid = false;
      }
      if (_passwordController.text.isEmpty) {
        _passwordError = "Unesi šifru";
        valid = false;
      } else if (_passwordController.text.length < 8) {
        _passwordError = "Šifra mora imati najmanje 8 znakova";
        valid = false;
      } else if (!RegExp(r'[A-Z]').hasMatch(_passwordController.text)) {
        _passwordError = "Šifra mora sadržavati bar jedno veliko slovo";
        valid = false;
      } else if (!RegExp(r'[a-z]').hasMatch(_passwordController.text)) {
        _passwordError = "Šifra mora sadržavati bar jedno malo slovo";
        valid = false;
      } else if (!RegExp(r'[0-9]').hasMatch(_passwordController.text)) {
        _passwordError = "Šifra mora sadržavati bar jedan broj";
        valid = false;
      } else if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(_passwordController.text)) {
        _passwordError = "Šifra mora sadržavati bar jedan specijalni znak";
        valid = false;
      }
    }
    if (isLogin) {
      if (_emailController.text.trim().isEmpty) {
        _emailError = "Unesi email";
        valid = false;
      }
      if (_passwordController.text.isEmpty) {
        _passwordError = "Unesi šifru";
        valid = false;
      }
    }

    setState(() {});

    if (!valid) return;

    setState(() => loading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (isLogin) {
        await auth.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (auth.role != "User") {
          setState(() {
            _formError =
                "Samo korisnici sa ulogom 'User' se mogu prijaviti na mobilnu aplikaciju.";
            loading = false;
          });
          await auth.logout();
          return;
        }
      } else {
        await auth.register(
          _firstNameController.text.trim(),
          _lastNameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
        // Ako odmah dobije token nakon registracije, provjeri i ovdje
        if (auth.role != "User") {
          setState(() {
            _formError =
                "Samo korisnici sa ulogom 'User' se mogu prijaviti na mobilnu aplikaciju.";
            loading = false;
          });
          await auth.logout();
          return;
        }
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainDashboard()),
      );
    } catch (e) {
      String errorMsg = e.toString().replaceAll('Exception:', '').trim();
      if (isLogin &&
          (errorMsg.toLowerCase().contains("lozinka") ||
              errorMsg.toLowerCase().contains("password") ||
              errorMsg.toLowerCase().contains("email"))) {
        setState(() => _formError = "Pogrešan email ili šifra.");
      } else {
        setState(() => _formError = errorMsg);
      }
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Container(
            constraints: BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book, size: 64),
                SizedBox(height: 20),
                Text(
                  isLogin ? "Prijava" : "Registracija",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (!isLogin)
                        Column(
                          children: [
                            TextField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: "Ime",
                                border: OutlineInputBorder(),
                                errorText: _firstNameError,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: "Prezime",
                                border: OutlineInputBorder(),
                                errorText: _lastNameError,
                              ),
                            ),
                            SizedBox(height: 12),
                          ],
                        ),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(),
                          errorText: _emailError,
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: "Šifra",
                          border: OutlineInputBorder(),
                          errorText: _passwordError,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[700],
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                        ),
                      ),
                      if (_formError != null)
                        Padding(
                          padding: EdgeInsets.only(top: 6, left: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _formError!,
                              style: TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : _submit,
                          child: loading
                              ? SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Text(isLogin ? "Prijavi se" : "Registruj se"),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: loading
                      ? null
                      : () => setState(() {
                          isLogin = !isLogin;
                          _firstNameError = null;
                          _lastNameError = null;
                          _emailError = null;
                          _passwordError = null;
                          _formError = null;
                          _showPassword = false;
                        }),
                  child: Text(
                    isLogin
                        ? "Nemaš nalog? Registruj se"
                        : "Imaš nalog? Prijavi se",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
