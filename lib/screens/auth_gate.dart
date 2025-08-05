import 'package:flutter/material.dart';
import 'package:roozterfaceapp/screens/login_screen.dart'; // Importa nuestra nueva pantalla

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Por ahora, mostramos directamente la pantalla de Login.
    // El 'onTap' por ahora no hará nada, lo conectaremos en el siguiente paso.
    return LoginScreen(onTap: () {});
  }
}
