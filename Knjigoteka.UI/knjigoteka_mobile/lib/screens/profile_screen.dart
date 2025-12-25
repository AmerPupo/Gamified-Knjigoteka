import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFF3F6FA),
        body: Center(
          child: Text(
            'Profil korisnika (uskoro).',
            style: TextStyle(fontSize: 21, color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }
}
