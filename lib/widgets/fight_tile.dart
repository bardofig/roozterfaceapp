// lib/widgets/fight_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/models/fight_model.dart';

class FightTile extends StatelessWidget {
  final FightModel fight;

  const FightTile({super.key, required this.fight});

  // Función para obtener el color y el icono basados en el resultado
  Map<String, dynamic> _getResultStyle(String result) {
    switch (result.toLowerCase()) {
      case 'victoria':
        return {'color': Colors.green.shade700, 'icon': Icons.emoji_events};
      case 'derrota':
        return {'color': Colors.red.shade700, 'icon': Icons.dangerous_outlined};
      case 'tabla':
        return {
          'color': Colors.orange.shade700,
          'icon': Icons.handshake_outlined,
        };
      default:
        return {'color': Colors.grey.shade700, 'icon': Icons.help_outline};
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _getResultStyle(fight.result);
    final Color resultColor = style['color'];
    final IconData resultIcon = style['icon'];

    // Formateador de fecha
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final String formattedDate = formatter.format(fight.date);

    return Container(
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
          // Fila superior: Resultado y Fecha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: resultColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(resultIcon, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      fight.result,
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

          // Detalles del combate
          Text.rich(
            TextSpan(
              style: TextStyle(color: Colors.grey.shade800, height: 1.5),
              children: [
                const TextSpan(
                  text: 'Lugar: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '${fight.location}\n'),
                const TextSpan(
                  text: 'Oponente: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: fight.opponent),
              ],
            ),
          ),

          // Notas (si existen)
          if (fight.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Notas: ${fight.notes}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
