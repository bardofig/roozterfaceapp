// lib/screens/rooster_details_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/models/fight_model.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/models/user_model.dart';
import 'package:roozterfaceapp/screens/add_fight_screen.dart';
import 'package:roozterfaceapp/screens/add_rooster_screen.dart';
import 'package:roozterfaceapp/services/fight_service.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';
import 'package:roozterfaceapp/widgets/fight_tile.dart';

class RoosterDetailsScreen extends StatelessWidget {
  final RoosterModel rooster;

  const RoosterDetailsScreen({super.key, required this.rooster});

  // Navega a la pantalla para editar los datos principales del gallo
  void _goToEditScreen(BuildContext context, String currentUserPlan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRoosterScreen(
          roosterToEdit: rooster,
          currentUserPlan: currentUserPlan,
        ),
      ),
    );
  }

  // Navega al formulario para AÑADIR un nuevo evento de combate
  void _goToAddFightScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFightScreen(roosterId: rooster.id),
        fullscreenDialog: true,
      ),
    );
  }

  // Navega al formulario para EDITAR un evento de combate existente
  void _goToEditFightScreen(BuildContext context, FightModel fight) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddFightScreen(roosterId: rooster.id, fightToEdit: fight),
        fullscreenDialog: true,
      ),
    );
  }

  // Widget de ayuda para construir las filas de detalles (Nombre: Valor)
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap:
                  true, // Permite que el texto largo salte a la siguiente línea
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('dd de MMMM de yyyy', 'es_ES');
    final String formattedBirthDate = formatter.format(
      rooster.birthDate.toDate(),
    );
    final RoosterService roosterService = RoosterService();
    final FightService fightService = FightService();

    // Lógica para determinar qué mostrar como linaje
    final String fatherDisplay =
        rooster.fatherName ?? rooster.fatherLineageText ?? 'No registrado';
    final String motherDisplay =
        rooster.motherName ?? rooster.motherLineageText ?? 'No registrada';

    return Scaffold(
      appBar: AppBar(
        title: Text(rooster.name),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: roosterService.getUserProfileStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: null,
                );
              }
              final userProfile = UserModel.fromFirestore(snapshot.data!);
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _goToEditScreen(context, userProfile.plan),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Imagen
            rooster.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: rooster.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 250,
                    placeholder: (context, url) => Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 50),
                    ),
                  )
                : Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.shield_outlined,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
                  ),

            // Sección de Información General
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rooster.name,
                    style: GoogleFonts.germaniaOne(fontSize: 32),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    context,
                    icon: Icons.badge,
                    label: 'Placa',
                    value: rooster.plate.isNotEmpty ? rooster.plate : 'N/A',
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    icon: Icons.cake,
                    label: 'Nacimiento',
                    value: formattedBirthDate,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    icon: Icons.monitor_heart,
                    label: 'Estado',
                    value: rooster.status,
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text("Linaje", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    icon: Icons.male,
                    label: 'Línea Paterna',
                    value: fatherDisplay,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    icon: Icons.female,
                    label: 'Línea Materna',
                    value: motherDisplay,
                  ),
                ],
              ),
            ),

            // Sección de Historial de Combate
            StreamBuilder<DocumentSnapshot>(
              stream: roosterService.getUserProfileStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final userProfile = UserModel.fromFirestore(snapshot.data!);
                if (userProfile.plan == 'iniciacion')
                  return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Eventos de Combate",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.black,
                            ),
                            onPressed: () => _goToAddFightScreen(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<FightModel>>(
                        stream: fightService.getFightsStream(rooster.id),
                        builder: (context, fightSnapshot) {
                          if (fightSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (!fightSnapshot.hasData ||
                              fightSnapshot.data!.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Text(
                                  "Este gallo aún no tiene eventos registrados.",
                                ),
                              ),
                            );
                          }

                          final fights = fightSnapshot.data!;
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: fights.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final fight = fights[index];
                              return FightTile(
                                fight: fight,
                                onTap: () =>
                                    _goToEditFightScreen(context, fight),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
