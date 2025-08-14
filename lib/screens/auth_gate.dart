// lib/screens/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roozterfaceapp/screens/home_screen.dart';
import 'package:roozterfaceapp/screens/login_or_register_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Mientras espera la decisión inicial de Firebase
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Si hay un usuario, vamos a HomeScreen.
          // El UserDataProvider se encargará de cargar los datos en segundo plano.
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          // Si no hay usuario, vamos a la pantalla de login/registro.
          else {
            return const LoginOrRegisterScreen();
          }
        },
      ),
    );
  }
}
