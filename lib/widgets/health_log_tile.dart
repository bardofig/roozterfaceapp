// lib/widgets/health_log_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/models/health_log_model.dart';

class HealthLogTile extends StatelessWidget {
  final HealthLogModel log;
  final VoidCallback onTap; // Parámetro para manejar el toque

  const HealthLogTile({
    super.key,
    required this.log,
    required this.onTap, // Lo hacemos requerido
  });

  IconData _getLogIcon(String logCategory) {
    switch (logCategory) {
      case 'Vacunación':
        return Icons.vaccines;
      case 'Desparasitación':
        return Icons.bug_report;
      case 'Suplemento/Vitamina':
        return Icons.local_drink;
      case 'Enfermedad/Tratamiento':
        return Icons.medical_services;
      default:
        return Icons.healing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final String formattedDate = formatter.format(log.date);

    return GestureDetector(
      // Envolvemos todo para que sea "tocable"
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _getLogIcon(log.logCategory),
              color: Theme.of(context).primaryColor,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        log.logCategory,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.productName,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (log.illnessOrCondition != null &&
                      log.illnessOrCondition!.isNotEmpty)
                    Text(
                      'Condición: ${log.illnessOrCondition}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  if (log.dosage != null && log.dosage!.isNotEmpty)
                    Text(
                      'Dosis: ${log.dosage}',
                      style: const TextStyle(fontSize: 12),
                    ),

                  if (log.notes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        'Notas: ${log.notes}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ), // Indicador visual
          ],
        ),
      ),
    );
  }
}
