// lib/widgets/rooster_tile.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';

class RoosterTile extends StatelessWidget {
  final RoosterModel rooster;
  final VoidCallback onTap;

  const RoosterTile({
    super.key,
    required this.rooster,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en venta':
        return Colors.blue.shade600;
      case 'activo':
        return Colors.green.shade600;
      case 'descansando':
        return Colors.orange.shade600;
      case 'herido':
        return Colors.purple.shade600;
      case 'vendido':
      case 'perdido en combate':
        return Colors.black87;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String priceDisplay =
        rooster.salePrice != null && rooster.salePrice! > 0
            ? NumberFormat.currency(locale: 'es_MX', symbol: '\$')
                .format(rooster.salePrice)
            : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          leading: Hero(
            tag: rooster.id,
            child: CircleAvatar(
              radius: 25,
              backgroundColor: theme.colorScheme.surface,
              child: rooster.imageUrl.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: rooster.imageUrl,
                        fit: BoxFit.cover,
                        width: 50,
                        height: 50,
                        placeholder: (ctx, url) =>
                            const CircularProgressIndicator(strokeWidth: 2),
                        errorWidget: (ctx, url, err) => const Icon(Icons.error),
                      ),
                    )
                  : Icon(rooster.sex == 'hembra' ? Icons.female : Icons.male,
                      color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          title: Row(
            children: [
              Icon(
                rooster.sex == 'hembra' ? Icons.female : Icons.male,
                color: rooster.sex == 'hembra'
                    ? Colors.pink.shade300
                    : Colors.blue.shade400,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rooster.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Text(
              'Placa: ${rooster.plate.isNotEmpty ? rooster.plate : "N/A"}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusColor(rooster.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rooster.status,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (rooster.status.toLowerCase() == 'en venta' &&
                  priceDisplay.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    priceDisplay,
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
