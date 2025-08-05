import 'dart:async';
import 'package:flutter/material.dart';
import 'package:roozterfaceapp/screens/auth_gate.dart';

// 1. Importa el paquete que acabamos de instalar
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
      // 2. Usamos un Stack para poder posicionar elementos libremente
      body: Stack(
        fit: StackFit.expand, // Para que el Stack ocupe toda la pantalla
        children: [
          // Widget 1: El contenido principal centrado
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 120, color: Colors.grey[800]),
                const SizedBox(height: 20),
                Text(
                  'RoozterFaceApp',
                  // 3. Aplicamos Google Fonts también al título para consistencia
                  style: GoogleFonts.orbitron(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          // Widget 2: La marca "CodigoBardo" en la parte inferior
          Positioned(
            bottom: 40.0, // A 40 píxeles del borde inferior
            left: 0,
            right: 0,
            child: Text(
              'by CodigoBardo',
              textAlign: TextAlign.center, // Centramos el texto horizontalmente
              // 4. Aquí está la magia: usamos la fuente Orbitron
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
