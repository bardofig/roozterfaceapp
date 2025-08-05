// lib/screens/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roozterfaceapp/screens/home_screen.dart'; // Importamos la nueva pantalla de inicio
import 'package:roozterfaceapp/screens/login_or_register_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // El 'stream' es la fuente de datos. 'authStateChanges()' emite un
        // objeto User si el usuario inicia sesión, y 'null' si cierra sesión.
        stream: FirebaseAuth.instance.authStateChanges(),

        // El 'builder' es una función que se reconstruye cada vez que el stream
        // emite un nuevo valor.
        builder: (context, snapshot) {
          // Caso 1: El usuario tiene una sesión activa.
          // 'snapshot.hasData' es true si el stream ha emitido un objeto User.
          if (snapshot.hasData) {
            return const HomeScreen(); // Lo llevamos a la pantalla de inicio.
          }
          // Caso 2: El usuario no tiene una sesión activa.
          // 'snapshot.hasData' es false.
          else {
            return const LoginOrRegisterScreen(); // Le mostramos el flujo de login/registro.
          }
        },
      ),
    );
  }
}
