// lib/widgets/fight_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/models/fight_model.dart';

class FightTile extends StatelessWidget {
  final FightModel fight;
  final VoidCallback onTap;

  const FightTile({super.key, required this.fight, required this.onTap});

  Map<String, dynamic> _getStatusStyle(String status, String? result) {
    if (status == 'Programado') {
      return {
        'color': Colors.blueGrey,
        'icon': Icons.schedule,
        'text': 'Programado',
      };
    }
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
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const Divider(height: 20),

            Text.rich(
              TextSpan(
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text: 'Lugar: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: '${fight.location}\n'),
                  if (fight.status == 'Completado')
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Oponente: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: fight.opponent ?? 'N/A'),
                      ],
                    ),
                ],
              ),
            ),

            // --- MOSTRAR DURACIÓN SI EXISTE ---
            if (fight.fightDuration != null && fight.fightDuration!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Duración: ${fight.fightDuration}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

            if (fight.status == 'Completado' && fight.survived != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(
                      fight.survived!
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      color: fight.survived! ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fight.survived! ? 'Sobrevivió' : 'No Sobrevivió',
                      style: TextStyle(
                        color: fight.survived! ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
