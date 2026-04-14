// lib/theme/theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- TEMA CLARO PREMIUM ---
ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFFF5F5F5),
    foregroundColor: const Color(0xFF121212),
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.outfit(
      color: const Color(0xFF121212),
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  colorScheme: const ColorScheme.light(
    surface: Color(0xFFFBFBFB),
    onSurface: Color(0xFF121212),
    primary: Color(0xFF121212),
    onPrimary: Colors.white,
    secondary: Color(0xFFB8860B), // Dorado Elegante (Dark Goldenrod)
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE8EAF6),
    onSecondaryContainer: Color(0xFF1A237E),
  ),
  scaffoldBackgroundColor: const Color(0xFFFBFBFB),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

// --- TEMA OSCURO PREMIUM ---
ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.outfit(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  colorScheme: const ColorScheme.dark(
    surface: Color(0xFF000000),
    onSurface: Colors.white,
    primary: Colors.white,
    onPrimary: Colors.black,
    secondary: Color(0xFFFFB300), // Ámbar Vibrante
    onSecondary: Colors.black,
    secondaryContainer: Color(0xFF1A1A1A),
    onSecondaryContainer: Color(0xFFFFB300),
  ),
  scaffoldBackgroundColor: Colors.black,
  cardTheme: CardThemeData(
    color: const Color(0xFF121212),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Colors.white10),
    ),
  ),
);
