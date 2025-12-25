import 'package:flutter/material.dart';
import 'package:knjigoteka_desktop/screens/admin_dashboard_screen.dart';
import 'package:knjigoteka_desktop/screens/employee_dashboard_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 350,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Knjigoteka Login',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Lozinka',
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
                  if (_error != null)
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(_error!, style: TextStyle(color: Colors.red)),
                    ),
                  SizedBox(height: 16),
                  _loading
                      ? CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            child: Text('Prijava'),
                            onPressed: () async {
                              setState(() {
                                _loading = true;
                                _error = null;
                              });
                              try {
                                await auth.login(
                                  _emailController.text,
                                  _passwordController.text,
                                );
                                if (auth.role == "Admin") {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AdminDashboardScreen(),
                                    ),
                                  );
                                } else if (auth.role == "Employee") {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EmployeeDashboardScreen(),
                                    ),
                                  );
                                } else {
                                  setState(() {
                                    _error = "Nepoznata uloga korisnika.";
                                  });
                                }
                              } catch (e) {
                                setState(() {
                                  _error = e
                                      .toString()
                                      .replaceAll('Exception:', '')
                                      .trim();
                                });
                              }
                              setState(() {
                                _loading = false;
                              });
                            },
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
