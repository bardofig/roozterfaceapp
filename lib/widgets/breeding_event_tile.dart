// lib/widgets/breeding_event_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/models/breeding_event_model.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/screens/breeding_details_screen.dart';

class BreedingEventTile extends StatelessWidget {
  final BreedingEventModel event;
  final VoidCallback onDelete;
  final String? currentRoosterId; // Lo mantenemos opcional por si se reutiliza

  const BreedingEventTile({
    super.key,
    required this.event,
    required this.onDelete,
    this.currentRoosterId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Obtenemos el galleraId del Provider para la navegación
    final activeGalleraId =
        Provider.of<UserDataProvider>(context, listen: false)
            .userProfile
            ?.activeGalleraId;

    final date =
        DateFormat('dd MMMM yyyy', 'es_ES').format(event.eventDate.toDate());

    // Lógica para determinar qué nombre mostrar para el padre
    final String fatherDisplay = event.externalFatherLineage?.isNotEmpty == true
        ? event.externalFatherLineage!
        : '${event.fatherName ?? "S/N"} (${event.fatherPlate?.isNotEmpty == true ? event.fatherPlate : "S/P"})';

    // Lógica para determinar qué nombre mostrar para la madre
    final String motherDisplay = event.externalMotherLineage?.isNotEmpty == true
        ? event.externalMotherLineage!
        : '${event.motherName ?? "S/N"} (${event.motherPlate?.isNotEmpty == true ? event.motherPlate : "S/P"})';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      clipBehavior: Clip.antiAlias, // Asegura que el InkWell respete los bordes
      child: InkWell(
        onTap: () {
          // Si no tenemos un galleraId, no hacemos nada (medida de seguridad)
          if (activeGalleraId == null) return;
          // Navegamos a la pantalla de detalles de la nidada
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BreedingDetailsScreen(
                galleraId: activeGalleraId,
                eventId: event.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cruza', style: theme.textTheme.titleLarge),
                  Text(date, style: theme.textTheme.bodySmall),
                ],
              ),
              const Divider(height: 16),
              _buildParentRow(
                context,
                icon: Icons.male,
                color: Colors.blue,
                label: 'Padre:',
                value: fatherDisplay,
              ),
              const SizedBox(height: 8),
              _buildParentRow(
                context,
                icon: Icons.female,
                color: Colors.pink,
                label: 'Madre:',
                value: motherDisplay,
              ),
              if (event.notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, left: 4.0),
                  child: Text('Notas: ${event.notes}',
                      style: theme.textTheme.bodyMedium),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Icono de flecha para indicar que es navegable
                  const Icon(Icons.chevron_right, color: Colors.grey),
                  IconButton(
                    icon:
                        Icon(Icons.delete_outline, color: Colors.red.shade400),
                    onPressed: onDelete,
                    tooltip: 'Borrar Registro',
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Expanded(child: Text(value, textAlign: TextAlign.right)),
      ],
    );
  }
}
