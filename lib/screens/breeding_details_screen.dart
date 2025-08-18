// lib/screens/breeding_details_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/models/breeding_event_model.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/screens/add_rooster_screen.dart';
import 'package:roozterfaceapp/services/breeding_service.dart';

class BreedingDetailsScreen extends StatefulWidget {
  final String galleraId;
  final String eventId;

  const BreedingDetailsScreen({
    super.key,
    required this.galleraId,
    required this.eventId,
  });

  @override
  State<BreedingDetailsScreen> createState() => _BreedingDetailsScreenState();
}

class _BreedingDetailsScreenState extends State<BreedingDetailsScreen> {
  final BreedingService _breedingService = BreedingService();

  @override
  Widget build(BuildContext context) {
    final currentUserPlan =
        Provider.of<UserDataProvider>(context, listen: false)
                .userProfile
                ?.plan ??
            'iniciacion';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalles de la Cruza y Nidada')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('galleras')
            .doc(widget.galleraId)
            .collection('breeding_events')
            .doc(widget.eventId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(
                child: Text('Este evento de cría ya no existe.'));
          }
          final event = BreedingEventModel.fromFirestore(snapshot.data!);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildParentsCard(context, event),
                const SizedBox(height: 16),
                _buildClutchManagementCard(context, event, currentUserPlan),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildParentsCard(BuildContext context, BreedingEventModel event) {
    final theme = Theme.of(context);
    final fatherDisplay = event.externalFatherLineage?.isNotEmpty == true
        ? event.externalFatherLineage!
        : '${event.fatherName ?? "S/N"} (${event.fatherPlate?.isNotEmpty == true ? event.fatherPlate : "S/P"})';
    final motherDisplay = event.externalMotherLineage?.isNotEmpty == true
        ? event.externalMotherLineage!
        : '${event.motherName ?? "S/N"} (${event.motherPlate?.isNotEmpty == true ? event.motherPlate : "S/P"})';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Padres de la Nidada', style: theme.textTheme.titleLarge),
            const Divider(),
            ListTile(
                leading: const Icon(Icons.male, color: Colors.blue),
                title: Text(fatherDisplay)),
            ListTile(
                leading: const Icon(Icons.female, color: Colors.pink),
                title: Text(motherDisplay)),
            if (event.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                child: Text('Notas de Cruza: ${event.notes}',
                    style: theme.textTheme.bodyMedium),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClutchManagementCard(
      BuildContext context, BreedingEventModel event, String currentUserPlan) {
    final theme = Theme.of(context);
    String expectedHatchDateStr = 'No calculable';
    if (event.incubationStartDate != null) {
      final expectedDate =
          event.incubationStartDate!.toDate().add(const Duration(days: 21));
      expectedHatchDateStr = DateFormat('dd/MM/yyyy').format(expectedDate);
    }
    double hatchRate = 0.0;
    if (event.eggCount != null &&
        event.chicksHatched != null &&
        event.eggCount! > 0) {
      hatchRate = event.chicksHatched! / event.eggCount!;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Gestión de Nidada', style: theme.textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.edit_note),
                onPressed: () => _showEditClutchDialog(context, event),
                tooltip: 'Editar datos de la nidada',
              ),
            ]),
            const Divider(),
            _buildInfoRow(
                'Huevos Puestos:', event.eggCount?.toString() ?? 'N/R'),
            _buildInfoRow(
                'Inicio de Incubación:',
                event.incubationStartDate != null
                    ? DateFormat('dd/MM/yyyy')
                        .format(event.incubationStartDate!.toDate())
                    : 'N/R'),
            _buildInfoRow('Eclosión Esperada:', expectedHatchDateStr,
                isCalculated: true),
            const Divider(height: 24, thickness: 1),
            _buildInfoRow(
                'Pollos Nacidos:', event.chicksHatched?.toString() ?? 'N/R'),
            _buildInfoRow(
                'Fecha de Eclosión:',
                event.hatchDate != null
                    ? DateFormat('dd/MM/yyyy').format(event.hatchDate!.toDate())
                    : 'N/R'),
            if (hatchRate > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Porcentaje de Eclosión:",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("${(hatchRate * 100).toStringAsFixed(1)}%",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ]),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                          value: hatchRate,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                          backgroundColor: Colors.grey.shade300,
                          color: Colors.green),
                    ]),
              ),
            const Divider(height: 24, thickness: 1),
            _buildInfoRow(
                'Notas de Nidada:',
                event.clutchNotes?.isNotEmpty == true
                    ? event.clutchNotes!
                    : 'Ninguna'),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Registrar Cría de esta Nidada'),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) {
                    return AddRoosterScreen(
                      activeGalleraId: widget.galleraId,
                      currentUserPlan: currentUserPlan,
                      initialFatherId: event.fatherId,
                      initialMotherId: event.motherId,
                      initialFatherLineage: event.externalFatherLineage,
                      initialMotherLineage: event.externalMotherLineage,
                    );
                  }));
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isCalculated = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCalculated
                      ? Theme.of(context).colorScheme.secondary
                      : null)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontStyle:
                          isCalculated ? FontStyle.italic : FontStyle.normal))),
        ],
      ),
    );
  }

  Future<void> _showEditClutchDialog(
      BuildContext context, BreedingEventModel event) async {
    final eggController =
        TextEditingController(text: event.eggCount?.toString() ?? '');
    final chicksController =
        TextEditingController(text: event.chicksHatched?.toString() ?? '');
    final notesController =
        TextEditingController(text: event.clutchNotes ?? '');
    DateTime? incubationDate = event.incubationStartDate?.toDate();
    DateTime? hatchDate = event.hatchDate?.toDate();

    await showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: const Text('Editar Datos de Nidada'),
                content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: eggController,
                        decoration:
                            const InputDecoration(labelText: 'Nº de Huevos'),
                        keyboardType: TextInputType.number),
                    TextField(
                        controller: chicksController,
                        decoration: const InputDecoration(
                            labelText: 'Nº de Pollos Nacidos'),
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    Text(
                        'Inicio Incubación: ${incubationDate != null ? DateFormat('dd/MM/yyyy').format(incubationDate!) : "No fijada"}'),
                    ElevatedButton(
                        child: const Text('Seleccionar Fecha'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                              context: context,
                              initialDate: incubationDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now());
                          if (picked != null)
                            setDialogState(() => incubationDate = picked);
                        }),
                    const SizedBox(height: 16),
                    Text(
                        'Fecha Eclosión: ${hatchDate != null ? DateFormat('dd/MM/yyyy').format(hatchDate!) : "No fijada"}'),
                    ElevatedButton(
                        child: const Text('Seleccionar Fecha'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                              context: context,
                              initialDate: hatchDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now());
                          if (picked != null)
                            setDialogState(() => hatchDate = picked);
                        }),
                    const SizedBox(height: 16),
                    TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                            labelText: 'Notas de la Nidada'),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences),
                  ]),
                ),
                actions: [
                  TextButton(
                      child: const Text('Cancelar'),
                      onPressed: () => Navigator.of(ctx).pop()),
                  ElevatedButton(
                      child: const Text('Guardar'),
                      onPressed: () {
                        _breedingService.updateClutchDetails(
                          galleraId: widget.galleraId,
                          eventId: event.id,
                          eggCount: int.tryParse(eggController.text),
                          chicksHatched: int.tryParse(chicksController.text),
                          incubationStartDate: incubationDate,
                          hatchDate: hatchDate,
                          clutchNotes: notesController.text,
                        );
                        Navigator.of(ctx).pop();
                      }),
                ],
              );
            },
          );
        });
  }
}
