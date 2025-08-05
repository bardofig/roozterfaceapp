// lib/widgets/fight_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/models/fight_model.dart';

class FightTile extends StatelessWidget {
  final FightModel fight;
  final VoidCallback
  onTap; // Para permitir que sea "tocable" y abrir el formulario de edición

  const FightTile({super.key, required this.fight, required this.onTap});

  // Función para obtener el estilo del chip de estado/resultado
  Map<String, dynamic> _getStatusStyle(String status, String? result) {
    if (status == 'Programado') {
      return {
        'color': Colors.blueGrey,
        'icon': Icons.schedule,
        'text': 'Programado',
      };
    }
    // Si está completado, usamos el resultado
    switch (result?.toLowerCase()) {
      case 'victoria':
        return {
          'color': Colors.green.shade700,
          'icon': Icons.emoji_events,
          'text': 'Victoria',
        };
      case 'derrota':
        return {
          'color': Colors.red.shade700,
          'icon': Icons.dangerous_outlined,
          'text': 'Derrota',
        };
      case 'tabla':
        return {
          'color': Colors.orange.shade700,
          'icon': Icons.handshake_outlined,
          'text': 'Tabla',
        };
      default:
        return {
          'color': Colors.grey.shade700,
          'icon': Icons.help_outline,
          'text': result ?? 'Completado',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _getStatusStyle(fight.status, fight.result);
    final Color chipColor = style['color'];
    final IconData chipIcon = style['icon'];
    final String chipText = style['text'];

    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final String formattedDate = formatter.format(fight.date);

    return GestureDetector(
      onTap: onTap, // Hacemos que toda la tarjeta responda al toque
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: Chip de estado/resultado y Fecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(chipIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        chipText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 20),

            // Detalles del evento
            Text.rich(
              TextSpan(
                style: TextStyle(color: Colors.grey.shade800, height: 1.5),
                children: [
                  const TextSpan(
                    text: 'Lugar: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: '${fight.location}\n'),
                  // Solo muestra el oponente si la pelea está completada
                  if (fight.status == 'Completado')
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Oponente: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: fight.opponent ?? 'No registrado'),
                      ],
                    ),
                ],
              ),
            ),

            // Muestra las notas correspondientes según el estado
            if (fight.status == 'Programado' &&
                fight.preparationNotes != null &&
                fight.preparationNotes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Notas Prep: ${fight.preparationNotes}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            if (fight.status == 'Completado' &&
                fight.postFightNotes != null &&
                fight.postFightNotes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Notas Post: ${fight.postFightNotes}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
