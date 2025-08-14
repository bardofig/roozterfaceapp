// lib/screens/sales_history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/screens/rooster_details_screen.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';
import 'package:roozterfaceapp/widgets/sale_tile.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final RoosterService _roosterService = RoosterService();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserDataProvider>(context);
    final activeGalleraId = userProvider.userProfile?.activeGalleraId;

    if (activeGalleraId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registro de Ventas')),
        body: const Center(
            child: Text('No hay una gallera activa seleccionada.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ventas'),
      ),
      body: StreamBuilder<List<RoosterModel>>(
        stream: _roosterService.getSalesHistoryStream(activeGalleraId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error al cargar ventas: ${snapshot.error}'));
          }

          final soldRoosters = snapshot.data ?? [];

          if (soldRoosters.isEmpty) {
            return const Center(
              child: Text(
                'Aún no tienes ventas registradas.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // Calculamos el total de ventas
          final double totalSales = soldRoosters.fold(
              0.0, (sum, item) => sum + (item.salePrice ?? 0.0));
          final formattedTotal = NumberFormat.currency(
            locale: 'es_MX',
            symbol: '\$',
          ).format(totalSales);

          return Column(
            children: [
              // Resumen Financiero
              _buildSummaryCard(formattedTotal),
              // Lista de Ventas
              Expanded(
                child: ListView.builder(
                  itemCount: soldRoosters.length,
                  itemBuilder: (context, index) {
                    final rooster = soldRoosters[index];
                    return SaleTile(
                      soldRooster: rooster,
                      onTap: () {
                        // Permite navegar a la ficha del gallo vendido para ver detalles
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RoosterDetailsScreen(rooster: rooster),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String formattedTotal) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: theme.dividerColor)),
      child: Column(
        children: [
          Text(
            'TOTAL DE VENTAS REGISTRADAS',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          Text(
            formattedTotal,
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.green.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
