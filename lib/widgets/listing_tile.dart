// lib/widgets/listing_tile.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ListingTile extends StatelessWidget {
  // Recibe un mapa de datos, ya que viene de una colección denormalizada
  final Map<String, dynamic> listingData;
  final VoidCallback onTap;

  const ListingTile({
    super.key,
    required this.listingData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Extraemos los datos del mapa con seguridad
    final String name = listingData['name'] ?? 'Sin Nombre';
    final String imageUrl = listingData['imageUrl'] ?? '';
    final String ownerName = listingData['ownerName'] ?? 'Criador Desconocido';
    final String galleraName =
        listingData['galleraName'] ?? 'Gallera Desconocida';
    final double salePrice =
        (listingData['salePrice'] as num? ?? 0.0).toDouble();

    final String priceDisplay = salePrice > 0
        ? NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(salePrice)
        : 'Consultar';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Colors.grey.shade300),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.shield_outlined,
                              color: Colors.grey, size: 50),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Criador: $ownerName',
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      galleraName,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      priceDisplay,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
