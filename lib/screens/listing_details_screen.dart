// lib/screens/listing_details_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/screens/chat_screen.dart';

class ListingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> listingData;

  const ListingDetailsScreen({
    super.key,
    required this.listingData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Extracción segura de todos los datos
    final String name = listingData['name'] ?? 'Sin Nombre';
    final String imageUrl = listingData['imageUrl'] ?? '';
    final String plate = listingData['plate'] ?? 'N/A';
    final String breedLine = listingData['breedLine'] ?? 'No registrada';
    final double salePrice =
        (listingData['salePrice'] as num? ?? 0.0).toDouble();
    final String ownerName = listingData['ownerName'] ?? 'Criador Anónimo';
    final String galleraName =
        listingData['galleraName'] ?? 'Gallera Desconocida';
    final String ownerUid = listingData['ownerUid'] ?? '';
    final String roosterId = listingData['originalRoosterId'] ?? '';

    final Timestamp? birthDateStamp = listingData['birthDate'];
    final String birthDate = birthDateStamp != null
        ? DateFormat('dd MMMM yyyy', 'es_ES').format(birthDateStamp.toDate())
        : 'No registrada';
    final String color = listingData['color'] ?? 'No registrado';
    final String combType = listingData['combType'] ?? 'No registrado';
    final String legColor = listingData['legColor'] ?? 'No registrado';

    // --- LÓGICA DE CASCADA PARA EL LINAJE ---
    final String fatherName = listingData['fatherName'] ?? '';
    final String fatherPlate = listingData['fatherPlate'] ?? '';
    final String fatherLineageText = listingData['fatherLineageText'] ?? '';

    String fatherDisplay;
    if (fatherName.isNotEmpty) {
      fatherDisplay =
          '$fatherName (${fatherPlate.isNotEmpty ? fatherPlate : "S/P"})';
    } else if (fatherLineageText.isNotEmpty) {
      fatherDisplay = fatherLineageText;
    } else {
      fatherDisplay = 'No registrado';
    }

    final String motherName = listingData['motherName'] ?? '';
    final String motherPlate = listingData['motherPlate'] ?? '';
    final String motherLineageText = listingData['motherLineageText'] ?? '';

    String motherDisplay;
    if (motherName.isNotEmpty) {
      motherDisplay =
          '$motherName (${motherPlate.isNotEmpty ? motherPlate : "S/P"})';
    } else if (motherLineageText.isNotEmpty) {
      motherDisplay = motherLineageText;
    } else {
      motherDisplay = 'No registrada';
    }
    // ---------------------------------------------

    final String formattedPrice = salePrice > 0
        ? NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(salePrice)
        : 'Precio a Consultar';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
              width: double.infinity,
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(color: Colors.grey[300]),
                      errorWidget: (c, u, e) => const Icon(Icons.broken_image),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                          child: Icon(Icons.shield_outlined,
                              size: 150, color: Colors.grey))),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text(formattedPrice,
                      style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold)),
                  const Divider(height: 32),
                  Text("Características", style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  _buildDetailRow(context,
                      icon: Icons.badge, label: 'Placa:', value: plate),
                  _buildDetailRow(context,
                      icon: Icons.cake_outlined,
                      label: 'Nacimiento:',
                      value: birthDate),
                  _buildDetailRow(context,
                      icon: Icons.shield,
                      label: 'Línea/Casta:',
                      value: breedLine),
                  _buildDetailRow(context,
                      icon: Icons.palette_outlined,
                      label: 'Color:',
                      value: color),
                  _buildDetailRow(context,
                      icon: Icons.content_cut,
                      label: 'Cresta:',
                      value: combType),
                  _buildDetailRow(context,
                      icon: Icons.square_foot,
                      label: 'Patas:',
                      value: legColor),
                  const Divider(height: 32),
                  Text("Linaje (Declarado por el Criador)",
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  _buildDetailRow(context,
                      icon: Icons.male,
                      label: 'Línea Paterna:',
                      value: fatherDisplay),
                  _buildDetailRow(context,
                      icon: Icons.female,
                      label: 'Línea Materna:',
                      value: motherDisplay),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Card(
                elevation: 0,
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Vendido por', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(ownerName, style: theme.textTheme.headlineSmall),
                      Text(galleraName,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Contactar al Criador'),
                        onPressed: ownerUid.isEmpty
                            ? null
                            : () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (_) {
                                  return ChatScreen(
                                    recipientId: ownerUid,
                                    recipientName: ownerName,
                                    subjectRoosterId: roosterId,
                                    subjectRoosterName: name,
                                  );
                                }));
                              },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context,
      {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 20),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }
}
