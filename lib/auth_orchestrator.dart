// lib/auth_orchestrator.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/providers/rooster_list_provider.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/screens/auth_gate.dart';

class AuthOrchestrator extends StatefulWidget {
  const AuthOrchestrator({super.key});

  @override
  State<AuthOrchestrator> createState() => _AuthOrchestratorState();
}

class _AuthOrchestratorState extends State<AuthOrchestrator> {
  String? _lastGalleraId;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDataProvider>(
      builder: (context, userProvider, child) {
        final activeGalleraId = userProvider.userProfile?.activeGalleraId;
        
        // Solo llamar a fetchRoosters si la gallera activa cambió
        if (activeGalleraId != _lastGalleraId) {
          _lastGalleraId = activeGalleraId;
          
          // Usar addPostFrameCallback para evitar llamar setState durante build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<RoosterListProvider>().fetchRoosters(activeGalleraId);
            }
          });
        }

        return const AuthGate();
      },
    );
  }
}
