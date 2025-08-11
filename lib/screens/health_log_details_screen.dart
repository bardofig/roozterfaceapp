// lib/screens/health_log_details_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/models/health_log_model.dart';
import 'package:roozterfaceapp/screens/add_health_log_screen.dart';
import 'package:roozterfaceapp/services/health_service.dart';

class HealthLogDetailsScreen extends StatelessWidget {
  final String galleraId;
  final String roosterId;
  final HealthLogModel log;

  const HealthLogDetailsScreen({
    super.key,
    required this.galleraId,
    required this.roosterId,
    required this.log,
  });

  // Navega al formulario en modo edición
  void _goToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddHealthLogScreen(
          galleraId: galleraId,
          roosterId: roosterId,
          logToEdit: log,
        ),
      ),
    );
  }

  // Lógica para borrar el registro
  void _deleteLog(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Borrado'),
        content: const Text(
          '¿Estás seguro de que quieres borrar este registro de salud?',
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
        final healthService = HealthService();
        await healthService.deleteHealthLog(
          galleraId: galleraId,
          roosterId: roosterId,
          logId: log.id,
        );
        Navigator.of(context).pop(); // Cierra esta pantalla de detalles
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Registro borrado.')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al borrar: $e')));
      }
    }
  }

  // Widget de ayuda para las filas de detalles
  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Registro'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _goToEditScreen(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteLog(context),
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Categoría', log.logCategory),
                const Divider(),
                _buildDetailRow(
                  'Fecha',
                  DateFormat('dd de MMMM de yyyy', 'es_ES').format(log.date),
                ),
                const Divider(),
                _buildDetailRow('Producto/Tratamiento', log.productName),
                if (log.illnessOrCondition != null &&
                    log.illnessOrCondition!.isNotEmpty) ...[
                  const Divider(),
                  _buildDetailRow('Condición', log.illnessOrCondition!),
                ],
                if (log.dosage != null && log.dosage!.isNotEmpty) ...[
                  const Divider(),
                  _buildDetailRow('Dosis', log.dosage!),
                ],
                if (log.notes.isNotEmpty) ...[
                  const Divider(),
                  _buildDetailRow('Notas', log.notes),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
