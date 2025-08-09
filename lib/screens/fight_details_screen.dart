// lib/screens/fight_details_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/models/fight_model.dart';
import 'package:roozterfaceapp/screens/add_fight_screen.dart';
import 'package:roozterfaceapp/services/fight_service.dart';

class FightDetailsScreen extends StatelessWidget {
  final String roosterId;
  final FightModel fight;

  const FightDetailsScreen({
    super.key,
    required this.roosterId,
    required this.fight,
  });

  void _goToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddFightScreen(roosterId: roosterId, fightToEdit: fight),
      ),
    );
  }

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
        await fightService.deleteFight(roosterId: roosterId, fightId: fight.id);
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 1);
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

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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

  // --- WIDGET DE AYUDA PARA FILAS DE DETALLES CORREGIDO (MANTIENE DISEÑO ORIGINAL) ---
  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    // Si el valor está vacío (excepto para notas), no mostramos la fila.
    if (value.isEmpty && !label.toLowerCase().contains('notas'))
      return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Alinear al inicio verticalmente
        children: [
          // La etiqueta ocupa un espacio fijo
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          // El valor es flexible y puede ocupar el resto del espacio
          Expanded(
            child: Text(
              value.isNotEmpty
                  ? value
                  : 'No hay notas.', // Texto por defecto para notas
              textAlign: TextAlign.right, // Alinear a la derecha
              style: TextStyle(color: valueColor),
            ),
          ),
        ],
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
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
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
      backgroundColor: Colors.grey[200],
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
                  // La fila de "Heridas" ahora funcionará con texto largo
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

            // La tarjeta de "Notas" también se beneficiará de la corrección
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
