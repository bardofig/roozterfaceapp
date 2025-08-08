// lib/theme/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:roozterfaceapp/theme/theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = lightTheme; // Por defecto, iniciamos con el tema claro

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData == darkTheme;

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners(); // Notifica a los widgets que escuchan para que se redibujen
  }

  void toggleTheme() {
    if (_themeData == lightTheme) {
      themeData = darkTheme;
    } else {
      themeData = lightTheme;
    }
  }
}
