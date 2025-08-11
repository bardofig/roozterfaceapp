// lib/theme/theme.dart

import 'package:flutter/material.dart';

// --- TEMA CLARO ---
ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey.shade300, // AppBar clara
    foregroundColor: Colors.black, // Iconos y texto de la AppBar negros
  ),
  colorScheme: ColorScheme.light(
    surface: Colors.grey.shade200, // Fondo principal de las pantallas
    primary: Colors.black, // Color primario (botones, FAB)
    onPrimary: Colors.white, // Texto sobre el color primario
    secondary: Colors.blue.shade800, // Color de acento
    onSurface: Colors.black, // Color del texto general
  ),
  // --- SECCIÓN CORREGIDA ---
  // Usamos TabBarThemeData, no TabBarTheme
  tabBarTheme: TabBarThemeData(
    labelColor: Colors.black, // Color del texto de la pestaña activa
    unselectedLabelColor:
        Colors.grey.shade700, // Color del texto de las inactivas
    indicatorColor: Colors.black, // Color de la línea inferior
  ),
  cardColor: Colors.white,
  // Otros estilos que quieras definir
);

// --- TEMA OSCURO ---
ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey.shade900, // AppBar oscura
    foregroundColor: Colors.white,
  ),
  colorScheme: ColorScheme.dark(
    surface: Colors.black,
    primary: Colors.white,
    secondary: Colors.amber.shade700,
  ),
  // --- SECCIÓN CORREGIDA ---
  // Usamos TabBarThemeData, no TabBarTheme
  tabBarTheme: TabBarThemeData(
    labelColor: Colors.white,
    unselectedLabelColor: Colors.grey.shade500,
    indicatorColor: Colors.white,
  ),
  cardColor: Colors.grey[850],
);
