import 'package:flutter/material.dart';
import 'package:knjigoteka_mobile/screens/settings_screen.dart';
import '../models/book.dart';
import 'home_screen.dart'; // tvoj HomeScreen koji prikazuje listu knjiga
import 'cart_screen.dart'; // placeholder za korpu
import 'history_screen.dart'; // placeholder za historiju
import 'book_details_screen.dart'; // detalji o knjizi

class MainDashboard extends StatefulWidget {
  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  Book? _selectedBook;

  void _openBookDetails(Book book) {
    setState(() {
      _selectedBook = book;
      _selectedIndex = 0;
    });
  }

  void _closeBookDetails() {
    setState(() {
      _selectedBook = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _selectedBook == null
          ? HomeScreen(onBookTap: _openBookDetails)
          : BookDetailsScreen(book: _selectedBook!, onClose: _closeBookDetails),
      CartScreen(),
      HistoryScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          setState(() {
            _selectedIndex = i;
            if (i != 0) _selectedBook = null;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF233348),
        unselectedItemColor: Colors.grey,
        backgroundColor: Color(0xFFF9F6FB),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Početna"),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Korpa",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "Historija",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}
