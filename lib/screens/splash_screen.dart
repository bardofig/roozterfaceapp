// lib/screens/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:roozterfaceapp/screens/auth_gate.dart';

// Importamos el paquete de Google Fonts
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthGate()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Contenido principal centrado
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 120, color: Colors.grey[800]),
                const SizedBox(height: 20),
                // CAMBIO: Nuevo texto y nueva fuente
                Text(
                  'RoozterFace',
                  style: GoogleFonts.germaniaOne(
                    // <-- ¡LA NUEVA FUENTE!
                    fontSize: 48, // Un tamaño más imponente
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[850],
                  ),
                ),
              ],
            ),
          ),
          // Marca "CodigoBardo" en la parte inferior
          Positioned(
            bottom: 40.0,
            left: 0,
            right: 0,
            child: Text(
              'by CodigoBardo',
              textAlign: TextAlign.center,
              // Usamos una fuente más limpia aquí para no competir con el logo
              style: GoogleFonts.orbitron(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
