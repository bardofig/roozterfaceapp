// lib/screens/sales_history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/screens/rooster_details_screen.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';
import 'package:roozterfaceapp/widgets/sale_tile.dart';

// Enum para definir los posibles filtros de forma clara.
enum SalesFilter { thisMonth, lastMonth, fullYear }

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final RoosterService _roosterService = RoosterService();

  // Guardamos el filtro seleccionado en el estado. Por defecto, "Este Mes".
  SalesFilter _selectedFilter = SalesFilter.thisMonth;

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
            // Manejamos el error del índice de forma explícita
            String errorMessage = 'Error al cargar ventas: ${snapshot.error}';
            if (snapshot.error.toString().contains('requires an index')) {
              errorMessage =
                  'La base de datos requiere un nuevo índice. Ejecuta la app en modo debug y sigue el enlace en la consola para crearlo.';
            }
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                    )));
          }

          final allSalesThisYear = snapshot.data ?? [];

          // --- LÓGICA DE FILTRADO EN EL CLIENTE ---
          final now = DateTime.now();
          final List<RoosterModel> filteredSales;

          switch (_selectedFilter) {
            case SalesFilter.thisMonth:
              filteredSales = allSalesThisYear.where((sale) {
                final saleDate = sale.saleDate!.toDate();
                return saleDate.year == now.year && saleDate.month == now.month;
              }).toList();
              break;
            case SalesFilter.lastMonth:
              final lastMonth = now.month - 1 == 0 ? 12 : now.month - 1;
              final yearOfLastMonth =
                  now.month - 1 == 0 ? now.year - 1 : now.year;
              filteredSales = allSalesThisYear.where((sale) {
                final saleDate = sale.saleDate!.toDate();
                return saleDate.year == yearOfLastMonth &&
                    saleDate.month == lastMonth;
              }).toList();
              break;
            case SalesFilter.fullYear:
              filteredSales = allSalesThisYear;
              break;
          }

          // Calculamos el total de ventas sobre la lista YA filtrada.
          final double totalSales = filteredSales.fold(
              0.0, (sum, item) => sum + (item.salePrice ?? 0.0));
          final formattedTotal = NumberFormat.currency(
            locale: 'es_MX',
            symbol: '\$',
          ).format(totalSales);

          if (allSalesThisYear.isEmpty) {
            return const Center(
                child: Text('No hay ventas registradas este año.',
                    style: TextStyle(fontSize: 18, color: Colors.grey)));
          }

          return Column(
            children: [
              _buildFilterChips(),
              _buildSummaryCard(formattedTotal),
              if (filteredSales.isEmpty)
                const Expanded(
                    child: Center(
                        child: Text(
                            'No hay ventas para el período seleccionado.',
                            style:
                                TextStyle(fontSize: 16, color: Colors.grey))))
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    itemCount: filteredSales.length,
                    itemBuilder: (context, index) {
                      final rooster = filteredSales[index];
                      return SaleTile(
                        soldRooster: rooster,
                        onTap: () {
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

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        alignment: WrapAlignment.center,
        children: <Widget>[
          ChoiceChip(
            label: const Text('Este Mes'),
            selected: _selectedFilter == SalesFilter.thisMonth,
            onSelected: (bool selected) {
              setState(() {
                _selectedFilter = SalesFilter.thisMonth;
              });
            },
          ),
          ChoiceChip(
            label: const Text('Mes Anterior'),
            selected: _selectedFilter == SalesFilter.lastMonth,
            onSelected: (bool selected) {
              setState(() {
                _selectedFilter = SalesFilter.lastMonth;
              });
            },
          ),
          ChoiceChip(
            label: const Text('Este Año'),
            selected: _selectedFilter == SalesFilter.fullYear,
            onSelected: (bool selected) {
              setState(() {
                _selectedFilter = SalesFilter.fullYear;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String formattedTotal) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'TOTAL DE VENTAS REGISTRADAS',
            style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            formattedTotal,
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
