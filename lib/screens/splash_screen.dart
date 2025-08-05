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
                const SizedBox(
                  height: 10,
                ), // Un poco menos de espacio para juntarlos
                // Texto de la marca con la fuente de impacto
                Text(
                  'Bienvenido a',
                  style: GoogleFonts.roboto(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[850],
                  ),
                ),
                const SizedBox(height: 15),

                // ¡AQUÍ ESTÁ EL CAMBIO!
                // Texto de bienvenida con la nueva fuente elegante
                Text(
                  'RoozterFace',
                  style: GoogleFonts.roboto(
                    // <-- ¡NUEVA FUENTE APLICADA!
                    fontSize:
                        40, // Tangerine necesita un tamaño más grande para ser legible
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
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
