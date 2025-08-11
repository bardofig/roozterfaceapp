// lib/screens/fight_details_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/models/fight_model.dart';
import 'package:roozterfaceapp/screens/add_fight_screen.dart';
import 'package:roozterfaceapp/services/fight_service.dart';

class FightDetailsScreen extends StatelessWidget {
  final String galleraId;
  final String roosterId;
  final FightModel fight;

  const FightDetailsScreen({
    super.key,
    required this.galleraId,
    required this.roosterId,
    required this.fight,
  });

  // Navega al formulario en modo edición
  void _goToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFightScreen(
          galleraId: galleraId,
          roosterId: roosterId,
          fightToEdit: fight,
        ),
      ),
    );
  }

  // Lógica para borrar el evento
  void _deleteFight(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Borrado'),
        content: const Text(
          '¿Estás seguro de que quieres borrar este evento de combate?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final fightService = FightService();
        await fightService.deleteFight(
          galleraId: galleraId,
          roosterId: roosterId,
          fightId: fight.id,
        );
        Navigator.of(context).pop(); // Cierra esta pantalla de detalles
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento de combate borrado.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al borrar: $e')));
      }
    }
  }

  // Widget de ayuda para las filas de detalles
  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'No hay notas.',
              textAlign: TextAlign.right,
              style: TextStyle(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  // Widget de ayuda para crear las tarjetas de sección
  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    // Si no hay hijos (filas de detalle), no muestra la tarjeta
    if (children.every(
      (widget) => widget is SizedBox && widget.height == 0.0,
    )) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = fight.status == 'Completado';
    final DateFormat formatter = DateFormat('dd de MMMM de yyyy', 'es_ES');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isCompleted ? 'Resultado del Combate' : 'Evento Programado',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _goToEditScreen(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteFight(context),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoCard(
              context: context,
              title: 'Detalles del Evento',
              icon: Icons.calendar_today,
              children: [
                _buildDetailRow('Fecha', formatter.format(fight.date)),
                _buildDetailRow('Lugar / Derby', fight.location),
                _buildDetailRow('Estado', fight.status),
              ],
            ),
            if (isCompleted)
              _buildInfoCard(
                context: context,
                title: 'Resultado del Combate',
                icon: Icons.sports_kabaddi,
                children: [
                  _buildDetailRow(
                    'Oponente',
                    fight.opponent ?? 'No especificado',
                  ),
                  _buildDetailRow(
                    'Resultado',
                    fight.result ?? 'No especificado',
                    valueColor: fight.result == 'Victoria'
                        ? Colors.green.shade700
                        : (fight.result == 'Derrota'
                              ? Colors.red.shade700
                              : null),
                  ),
                  _buildDetailRow(
                    'Arma Utilizada',
                    fight.weaponType ?? 'No especificado',
                  ),
                  _buildDetailRow(
                    'Duración',
                    fight.fightDuration ?? 'No especificado',
                  ),
                  _buildDetailRow(
                    'Heridas Sufridas',
                    fight.injuriesSustained ?? 'Ninguna',
                  ),
                  if (fight.survived != null)
                    _buildDetailRow(
                      'Supervivencia',
                      fight.survived! ? 'Sobrevivió' : 'No Sobrevivió',
                      valueColor: fight.survived!
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                ],
              ),
            _buildInfoCard(
              context: context,
              title: 'Notas y Observaciones',
              icon: Icons.notes,
              children: [
                _buildDetailRow('De Preparación', fight.preparationNotes ?? ''),
                if (isCompleted)
                  _buildDetailRow('Post-Combate', fight.postFightNotes ?? ''),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
