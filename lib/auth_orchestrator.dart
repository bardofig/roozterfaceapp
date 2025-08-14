// lib/auth_orchestrator.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Importamos el scheduler
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/providers/rooster_list_provider.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/screens/auth_gate.dart';

class AuthOrchestrator extends StatelessWidget {
  const AuthOrchestrator({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el UserDataProvider. Este Consumer se reconstruirá
    // cada vez que el estado de login, logout o el perfil del usuario cambie.
    return Consumer<UserDataProvider>(
      builder: (context, userProvider, child) {
        // --- LA CORRECCIÓN DEFINITIVA ---
        // Usamos un post-frame callback para dar la orden DESPUÉS de que el
        // ciclo de construcción de este widget haya terminado.
        SchedulerBinding.instance.addPostFrameCallback((_) {
          // Usamos 'read' porque estamos en un callback, no en el método build.
          final roosterProvider = context.read<RoosterListProvider>();
          final activeGalleraId = userProvider.userProfile?.activeGalleraId;

          // Le damos la orden al proveedor de gallos basándonos en el estado
          // MÁS RECIENTE del proveedor de usuario.
          roosterProvider.fetchRoosters(activeGalleraId);
        });

        // El trabajo de orquestación ha sido agendado. Ahora, devolvemos
        // la puerta de autenticación para que decida qué pantalla mostrar.
        return const AuthGate();
      },
    );
  }
}
