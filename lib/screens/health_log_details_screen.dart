// lib/screens/health_log_details_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/models/health_log_model.dart';
import 'package:roozterfaceapp/screens/add_health_log_screen.dart';
import 'package:roozterfaceapp/services/health_service.dart';

class HealthLogDetailsScreen extends StatelessWidget {
  final String roosterId;
  final HealthLogModel log;

  const HealthLogDetailsScreen({
    super.key,
    required this.roosterId,
    required this.log,
  });

  void _goToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddHealthLogScreen(roosterId: roosterId, logToEdit: log),
      ),
    );
  }

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
          roosterId: roosterId,
          logId: log.id,
        );
        Navigator.of(context).pop(); // Cierra la pantalla de detalles
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Registro de Salud'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _goToEditScreen(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteLog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Categoría', log.logCategory),
            const Divider(),
            _buildDetailRow('Fecha', DateFormat('dd/MM/yyyy').format(log.date)),
            const Divider(),
            _buildDetailRow('Producto/Tratamiento', log.productName),
            const Divider(),
            if (log.illnessOrCondition != null &&
                log.illnessOrCondition!.isNotEmpty)
              _buildDetailRow('Condición', log.illnessOrCondition!),
            if (log.illnessOrCondition != null &&
                log.illnessOrCondition!.isNotEmpty)
              const Divider(),
            if (log.dosage != null && log.dosage!.isNotEmpty)
              _buildDetailRow('Dosis', log.dosage!),
            if (log.dosage != null && log.dosage!.isNotEmpty) const Divider(),
            if (log.notes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(log.notes),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
