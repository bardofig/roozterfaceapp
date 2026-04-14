// lib/widgets/dashboard_summary.dart

import 'package:flutter/material.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';

class DashboardSummary extends StatelessWidget {
  final List<RoosterModel> roosters;

  const DashboardSummary({super.key, required this.roosters});

  @override
  Widget build(BuildContext context) {
    if (roosters.isEmpty) return const SizedBox.shrink();

    final total = roosters.length;
    final males = roosters.where((r) => r.sex == 'macho').length;
    final females = roosters.where((r) => r.sex == 'hembra').length;
    final forSale = roosters.where((r) => r.status.toLowerCase() == 'en venta').length;
    final sold = roosters.where((r) => r.status.toLowerCase() == 'vendido').length;

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildStatCard(
            context,
            'Total',
            total.toString(),
            Icons.inventory_2_outlined,
            Colors.blue,
          ),
          _buildStatCard(
            context,
            'Machos',
            males.toString(),
            Icons.male,
            Colors.orange,
          ),
          _buildStatCard(
            context,
            'Hembras',
            females.toString(),
            Icons.female,
            Colors.pink,
          ),
          _buildStatCard(
            context,
            'En Venta',
            forSale.toString(),
            Icons.monetization_on_outlined,
            Colors.green,
          ),
          _buildStatCard(
            context,
            'Vendidos',
            sold.toString(),
            Icons.check_circle_outline,
            Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
