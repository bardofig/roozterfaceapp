// lib/screens/profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roozterfaceapp/models/user_model.dart';
import 'package:roozterfaceapp/screens/edit_profile_screen.dart'; // Importamos la nueva pantalla
import 'package:roozterfaceapp/services/rooster_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : 'No especificado',
                  style: TextStyle(color: Colors.grey[800], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos RoosterService para obtener el perfil, ya que ya tiene el método
    final RoosterService roosterService = RoosterService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[200],
      body: StreamBuilder<DocumentSnapshot>(
        stream: roosterService.getUserProfileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No se pudo cargar el perfil.'));
          }

          final userProfile = UserModel.fromFirestore(snapshot.data!);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Información de la Cuenta',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            // --- ¡BOTÓN DE EDITAR! ---
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(
                                      userProfile: userProfile,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          icon: Icons.person,
                          label: 'Nombre',
                          value: userProfile.fullName,
                        ),
                        _buildInfoRow(
                          context,
                          icon: Icons.email,
                          label: 'Email',
                          value: userProfile.email,
                        ),
                        _buildInfoRow(
                          context,
                          icon: Icons.phone_android,
                          label: 'Teléfono',
                          value: userProfile.mobilePhone,
                        ),
                        _buildInfoRow(
                          context,
                          icon: Icons.workspace_premium,
                          label: 'Plan Actual',
                          value: userProfile.plan.toUpperCase(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dirección de Contacto',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          icon: Icons.home,
                          label: 'Calle y Número',
                          value: '${userProfile.street} ${userProfile.number}',
                        ),
                        _buildInfoRow(
                          context,
                          icon: Icons.signpost,
                          label: 'Colonia',
                          value: userProfile.neighborhood,
                        ),
                        _buildInfoRow(
                          context,
                          icon: Icons.location_city,
                          label: 'Ciudad / C.P.',
                          value:
                              '${userProfile.city}, C.P. ${userProfile.postalCode}',
                        ),
                        _buildInfoRow(
                          context,
                          icon: Icons.public,
                          label: 'País',
                          value: userProfile.country,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
