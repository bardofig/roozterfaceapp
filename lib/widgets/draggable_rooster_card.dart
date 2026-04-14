// lib/widgets/draggable_rooster_card.dart

import 'package:flutter/material.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/widgets/optimized_cached_image.dart';

class DraggableRoosterCard extends StatelessWidget {
  final RoosterModel rooster;

  const DraggableRoosterCard({super.key, required this.rooster});

  @override
  Widget build(BuildContext context) {
    // Definimos el widget base de la tarjeta
    Widget cardContent = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Hero(
              tag: 'drag_${rooster.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: rooster.imageUrl.isNotEmpty
                    ? OptimizedCachedImage(
                        imageUrl: rooster.imageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey[300],
                        child: Icon(Icons.pets, size: 20, color: Colors.grey[600]),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rooster.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Placa: ${rooster.plate}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return LongPressDraggable<RoosterModel>(
      data: rooster,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 200,
          child: cardContent,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: cardContent,
      ),
      child: cardContent,
    );
  }
}
