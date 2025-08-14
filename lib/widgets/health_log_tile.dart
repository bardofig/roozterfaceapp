// lib/widgets/health_log_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/models/health_log_model.dart';

class HealthLogTile extends StatelessWidget {
  final HealthLogModel log;
  final VoidCallback onTap;

  const HealthLogTile({super.key, required this.log, required this.onTap});

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
    final theme = Theme.of(context); // Obtenemos el tema
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final String formattedDate = formatter.format(log.date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          // --- CORRECCIÓN: Usamos colores del tema ---
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _getLogIcon(log.logCategory),
              color: theme.colorScheme.secondary,
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
                      Text(formattedDate, style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.productName,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (log.illnessOrCondition != null &&
                      log.illnessOrCondition!.isNotEmpty)
                    Text(
                      'Condición: ${log.illnessOrCondition}',
                      style: theme.textTheme.bodySmall,
                    ),
                  if (log.dosage != null && log.dosage!.isNotEmpty)
                    Text(
                      'Dosis: ${log.dosage}',
                      style: theme.textTheme.bodySmall,
                    ),
                  if (log.notes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        'Notas: ${log.notes}',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.7,
                          ),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.dividerColor),
          ],
        ),
      ),
    );
  }
}
