import 'package:flutter/material.dart';
import 'package:roozterfaceapp/screens/login_screen.dart';
import 'package:roozterfaceapp/screens/register_screen.dart';

class LoginOrRegisterScreen extends StatefulWidget {
  const LoginOrRegisterScreen({super.key});

  @override
  State<LoginOrRegisterScreen> createState() => _LoginOrRegisterScreenState();
}

class _LoginOrRegisterScreenState extends State<LoginOrRegisterScreen> {
  // Inicialmente, mostramos la página de login
  bool showLoginPage = true;

  // Método para alternar entre las dos páginas
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      // Si showLoginPage es true, muestra LoginScreen y pásale la función para alternar
      return LoginScreen(onTap: togglePages);
    } else {
      // Si es false, muestra RegisterScreen y pásale la misma función
      return RegisterScreen(onTap: togglePages);
    }
  }
}
