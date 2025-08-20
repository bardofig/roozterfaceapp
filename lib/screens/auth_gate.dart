// lib/screens/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/screens/login_or_register_screen.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/screens/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Muestra un indicador de carga mientras se determina el estado de autenticación inicial.
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // --- PRIMER PUESTO DE CONTROL: ¿Está el usuario autenticado en Firebase? ---
        if (authSnapshot.hasData) {
          // Si está autenticado, escuchamos al UserDataProvider para el segundo puesto de control.
          return Consumer<UserDataProvider>(
            builder: (context, userProvider, child) {
              // --- SEGUNDO PUESTO DE CONTROL: ¿Está el perfil de Firestore cargado? ---
              if (userProvider.isLoading || userProvider.userProfile == null) {
                // Si el perfil se está cargando O AÚN no se ha cargado (caso de login rápido),
                // mostramos una pantalla de carga. Esto previene la condición de carrera.
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                // ¡ÉXITO TOTAL! Tenemos autenticación y perfil. Mostramos HomeScreen.
                // HomeScreen tiene su propio Scaffold, por lo que lo devolvemos directamente.
                return const HomeScreen();
              }
            },
          );
        } else {
          // No hay usuario autenticado. Mostramos el flujo de Login/Registro.
          // LoginOrRegister también tendrá su propio Scaffold.
          return const LoginOrRegisterScreen();
        }
      },
    );
  }
}
