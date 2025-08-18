// lib/widgets/sale_tile.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';

class SaleTile extends StatelessWidget {
  final RoosterModel soldRooster;
  final VoidCallback onTap;

  const SaleTile({
    super.key,
    required this.soldRooster,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final salePrice = NumberFormat.currency(locale: 'es_MX', symbol: '\$')
        .format(soldRooster.salePrice ?? 0);
    final saleDate = soldRooster.saleDate != null
        ? DateFormat('dd MMMM yyyy', 'es_ES')
            .format(soldRooster.saleDate!.toDate())
        : 'Fecha no registrada';

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
                width: 80,
                height: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: soldRooster.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: soldRooster.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Colors.grey.shade300),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.shield_outlined,
                              color: Colors.grey, size: 40),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(soldRooster.name,
                        style: theme.textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      'Vendido a: ${soldRooster.buyerName?.isNotEmpty == true ? soldRooster.buyerName : "No registrado"}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(saleDate, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                salePrice,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
