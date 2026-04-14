// lib/screens/profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roozterfaceapp/screens/edit_profile_screen.dart';
import 'package:roozterfaceapp/screens/create_partido_screen.dart'; // ✅ NUEVO
import 'package:roozterfaceapp/screens/partido_management_screen.dart'; // ✅ NUEVO
import 'package:roozterfaceapp/services/rooster_service.dart';
import 'package:roozterfaceapp/services/partido_service.dart'; // ✅ NUEVO
import 'package:roozterfaceapp/models/partido_model.dart'; // ✅ NUEVO
import 'package:roozterfaceapp/models/user_model.dart'; // ✅ NUEVO

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
                const SizedBox(height: 20),
                // --- SECCIÓN DE PARTIDO ---
                _buildPartidoSection(context, userProfile),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPartidoSection(BuildContext context, UserModel userProfile) {
    if (userProfile.activePartidoId == null || userProfile.activePartidoId!.isEmpty) {
      return Card(
        elevation: 2,
        color: Colors.amber.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.amber.shade200)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.amber, size: 28),
                  SizedBox(width: 12),
                  Text('¿No tienes un equipo?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Crea tu propio Partido para competir y gestionar a tus socios galleros.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePartidoScreen())),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                child: const Text('REGISTRAR MI PARTIDO'),
              ),
            ],
          ),
        ),
      );
    }

    // Si tiene partido, mostramos su nombre y acceso a gestión
    return StreamBuilder<PartidoModel?>(
      stream: PartidoService().getActivePartidoStream(userProfile.activePartidoId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) return const SizedBox();
        final partido = snapshot.data!;
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.amber,
                  backgroundImage: partido.logoUrl != null ? NetworkImage(partido.logoUrl!) : null,
                  child: partido.logoUrl == null ? const Icon(Icons.shield, color: Colors.white, size: 30) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MI PARTIDO ACTIVOS', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(partido.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => PartidoManagementScreen(partidoId: partido.id))
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
