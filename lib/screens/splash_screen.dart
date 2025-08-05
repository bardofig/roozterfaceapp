// lib/screens/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:roozterfaceapp/screens/auth_gate.dart';
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Widget del Título Superior
            Positioned(
              top: 40.0,
              left: 0,
              right: 0,
              child: Text(
                'RoozterFace',
                textAlign: TextAlign.center,
                // --- ¡AQUÍ ESTÁ EL CAMBIO DE FUENTE! ---
                style: GoogleFonts.cinzel(
                  fontSize: 40,
                  fontWeight:
                      FontWeight.bold, // Cinzel se ve muy bien en negrita
                  color: const Color(0xFFD4AF37),
                  shadows: [
                    const Shadow(
                      blurRadius: 10.0,
                      color: Colors.black54,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
            ),

            // Widget del Logo (sin cambios)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Widget de la marca "by CodigoBardo" (sin cambios)
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
      ),
    );
  }
}
