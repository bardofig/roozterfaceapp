// lib/widgets/health_log_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/models/health_log_model.dart';

class HealthLogTile extends StatelessWidget {
  final HealthLogModel log;

  const HealthLogTile({super.key, required this.log});

  // Función para obtener un icono representativo según el tipo de registro
  IconData _getLogIcon(String logType) {
    switch (logType.toLowerCase()) {
      case 'vacunación':
        return Icons.vaccines;
      case 'desparasitación':
        return Icons.bug_report;
      case 'vitamina':
        return Icons.local_drink;
      case 'tratamiento':
        return Icons.medical_services;
      default:
        return Icons.healing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final String formattedDate = formatter.format(log.date);

    return Container(
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
          // Icono a la izquierda
          Icon(
            _getLogIcon(log.logType),
            color: Theme.of(context).primaryColor,
            size: 30,
          ),
          const SizedBox(width: 12),
          // Columna con toda la información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tipo de registro en negrita
                    Text(
                      log.logType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    // Fecha
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Descripción del producto o tratamiento
                Text(
                  log.description,
                  style: TextStyle(color: Colors.grey.shade800),
                ),
                // Notas (si existen)
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
        ],
      ),
    );
  }
}
