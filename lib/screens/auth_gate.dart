// lib/screens/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/screens/complete_profile_screen.dart'; // <-- ¡NUEVA IMPORTACIÓN!
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
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // PUESTO DE CONTROL 1: ¿Usuario autenticado en Firebase?
        if (authSnapshot.hasData) {
          return Consumer<UserDataProvider>(
            builder: (context, userProvider, child) {
              // PUESTO DE CONTROL 2: ¿Perfil de Firestore cargado?
              if (userProvider.isLoading || userProvider.userProfile == null) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // --- ¡NUEVO PUESTO DE CONTROL 3! ---
              // ¿El perfil del usuario está completo?
              // Usamos `fullName` como indicador clave. Si está vacío, el perfil no se ha completado.
              final isProfileComplete =
                  userProvider.userProfile!.fullName.trim().isNotEmpty;

              if (isProfileComplete) {
                // Si el perfil está completo, va a la pantalla principal.
                return const HomeScreen();
              } else {
                // Si el perfil NO está completo, se le dirige a la pantalla para completarlo.
                return const CompleteProfileScreen();
              }
            },
          );
        } else {
          // No hay usuario autenticado.
          return const LoginOrRegisterScreen();
        }
      },
    );
  }
}
