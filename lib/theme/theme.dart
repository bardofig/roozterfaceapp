// lib/theme/theme.dart

import 'package:flutter/material.dart';

// Tema Claro
ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: Colors.grey.shade200, // Fondo principal
    primary: Colors.grey.shade800, // Color principal (AppBar, botones)
    secondary: Colors.blue.shade700, // Color de acento
    onSurface: Colors.black, // Color del texto sobre el fondo
    onPrimary: Colors.white, // Color del texto sobre el color primario
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey[900],
    foregroundColor: Colors.white,
  ),
  cardColor: Colors.white,
);

// Tema Oscuro
ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: Colors.grey.shade900,
    primary: Colors.white,
    secondary: Colors.amber.shade700,
    onSurface: Colors.white,
    onPrimary: Colors.black,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
  ),
  cardColor: Colors.grey[850],
);
