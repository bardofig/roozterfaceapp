// lib/screens/gallera_switcher_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roozterfaceapp/models/user_model.dart';
import 'package:roozterfaceapp/services/gallera_service.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';
import 'package:roozterfaceapp/services/user_service.dart';

class GalleraSwitcherScreen extends StatelessWidget {
  const GalleraSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos los servicios que ya existen
    final roosterService = RoosterService();
    final galleraService = GalleraService();
    final userService = UserService();

    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar de Gallera')),
      body: StreamBuilder<DocumentSnapshot>(
        // 1. Obtenemos el perfil del usuario para saber a qué galleras pertenece
        stream: roosterService.getUserProfileStream(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userProfile = UserModel.fromFirestore(userSnapshot.data!);
          final List<String> galleraIds = userProfile.galleraIds;

          if (galleraIds.isEmpty) {
            return const Center(
              child: Text("No perteneces a ninguna gallera."),
            );
          }

          // 2. Usando los IDs, obtenemos los datos de cada gallera
          return StreamBuilder<QuerySnapshot>(
            stream: galleraService.getGallerasByIds(galleraIds),
            builder: (context, gallerasSnapshot) {
              if (!gallerasSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final galleras = gallerasSnapshot.data!.docs;

              return ListView.builder(
                itemCount: galleras.length,
                itemBuilder: (context, index) {
                  final gallera = galleras[index];
                  final bool isActive =
                      gallera.id == userProfile.activeGalleraId;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: Icon(
                        isActive
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isActive ? Colors.green : null,
                      ),
                      title: Text(gallera['name'] ?? 'Gallera sin nombre'),
                      subtitle: Text(
                        gallera['ownerId'] == userProfile.uid
                            ? 'Eres el Propietario'
                            : 'Eres Miembro',
                      ),
                      // La opción de seleccionar se deshabilita si ya es la gallera activa
                      onTap: isActive
                          ? null
                          : () async {
                              try {
                                await userService.setActiveGallera(gallera.id);
                                if (context.mounted)
                                  Navigator.of(context).pop();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error al cambiar de gallera: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
