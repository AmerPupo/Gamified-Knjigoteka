import 'package:flutter/material.dart';
import 'package:knjigoteka_desktop/providers/auth_provider.dart';
import 'package:knjigoteka_desktop/screens/books_screen.dart';
import 'package:knjigoteka_desktop/screens/branches_screen.dart';
import 'package:knjigoteka_desktop/screens/employees_screen.dart';
import 'package:knjigoteka_desktop/screens/orders_screen.dart';
import 'package:knjigoteka_desktop/screens/sifarnici_screen.dart';
import 'package:knjigoteka_desktop/screens/settings_screen.dart';
import 'package:provider/provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  static const List<String> _menuTitles = [
    "Poslovnice",
    "Uposlenici",
    "Narudžbe",
    "Knjige",
    "Šifarnici",
    "Postavke",
  ];

  static final List<Widget> _screens = [
    BranchesScreen(),
    EmployeesScreen(),
    OrdersScreen(),
    BooksScreen(),
    SifarniciScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 220,
            color: Color(0xFF233348),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 32),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Knjigoteka",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 32),
                ...List.generate(_menuTitles.length, (idx) {
                  final bool selected = _selectedIndex == idx;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4,
                    ),
                    child: Material(
                      color: selected
                          ? Colors.white.withOpacity(0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _selectedIndex = idx),
                        child: Container(
                          decoration: selected
                              ? BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 1.2,
                                  ),
                                )
                              : null,
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          child: Row(
                            children: [
                              _getSidebarIcon(idx, selected),
                              SizedBox(width: 14),
                              Text(
                                _menuTitles[idx],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 16,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                Spacer(),
                Divider(color: Colors.white30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.white70),
                    title: Text(
                      "Odjavi se",
                      style: TextStyle(color: Colors.white70),
                    ),
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Row(
                            children: [
                              Expanded(child: Text("Odjavi se?")),
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () => Navigator.pop(ctx, false),
                              ),
                            ],
                          ),
                          content: Text(
                            "Da li ste sigurni da se želite odjaviti?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text("Odustani"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: Text("Odjavi se"),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).logout();

                        Navigator.of(context).pushReplacementNamed('/');
                      }
                    },
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Color(0xFFF3F6FA),
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Icon _getSidebarIcon(int idx, bool selected) {
    Color iconColor = selected ? Colors.amberAccent : Colors.white;
    switch (idx) {
      case 0:
        return Icon(Icons.store, color: iconColor);
      case 1:
        return Icon(Icons.people, color: iconColor);
      case 2:
        return Icon(Icons.shopping_bag, color: iconColor);
      case 3:
        return Icon(Icons.book, color: iconColor);
      case 4:
        return Icon(Icons.category, color: iconColor);
      case 5:
        return Icon(Icons.settings, color: iconColor);
      default:
        return Icon(Icons.circle, color: iconColor);
    }
  }
}
