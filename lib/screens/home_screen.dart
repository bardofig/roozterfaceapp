// lib/screens/home_screen.dart

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página de Inicio'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text('¡Has iniciado sesión!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
