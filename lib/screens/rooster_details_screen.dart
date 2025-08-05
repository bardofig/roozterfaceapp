// lib/screens/rooster_details_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/models/user_model.dart';
import 'package:roozterfaceapp/screens/add_rooster_screen.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';

class RoosterDetailsScreen extends StatelessWidget {
  final RoosterModel rooster;

  const RoosterDetailsScreen({super.key, required this.rooster});

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
            child: Text(value, textAlign: TextAlign.right, softWrap: true),
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
          ],
        ),
      ),
    );
  }
}
