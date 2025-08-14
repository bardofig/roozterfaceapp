// lib/theme/theme.dart

import 'package:flutter/material.dart';

// --- TEMA CLARO CON COLORES PASTEL PARA EL CHAT ---
ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey.shade300,
    foregroundColor: Colors.black,
    elevation: 1, // Añade una sombra sutil
  ),
  colorScheme: ColorScheme.light(
    surface: Colors.grey.shade200,
    primary: Colors.black,
    onPrimary: Colors.white,
    secondary: Colors.blue.shade800,
    onSurface: Colors.black,
    // Colores para contenedores del chat
    secondaryContainer: const Color(0xFFE3F2FD),
    onSecondaryContainer: const Color(0xFF1565C0),
    surfaceVariant: Colors.grey.shade300,
  ),
  // --- SECCIÓN CORREGIDA Y DEFINITIVA ---
  tabBarTheme: const TabBarThemeData(
    labelColor: Colors.black,
    unselectedLabelColor: Colors.black54,
    indicatorColor: Colors.black,
  ),
  cardColor: Colors.white,
);

// --- TEMA OSCURO CON COLORES SUTILES PARA EL CHAT ---
ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey.shade900,
    foregroundColor: Colors.white,
    elevation: 1, // Añade una sombra sutil
  ),
  colorScheme: ColorScheme.dark(
    surface: Colors.black,
    primary: Colors.white,
    secondary: Colors.amber.shade700,
    // Colores para contenedores del chat
    secondaryContainer: const Color(0xFF263238),
    onSecondaryContainer: const Color(0xFFCFD8DC),
    surfaceVariant: Colors.grey.shade800,
  ),
  // --- SECCIÓN CORREGIDA Y DEFINITIVA ---
  tabBarTheme: const TabBarThemeData(
    labelColor: Colors.white,
    unselectedLabelColor: Colors.white70,
    indicatorColor: Colors.white,
  ),
  cardColor: Colors.grey[850],
);
