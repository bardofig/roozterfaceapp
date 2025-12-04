// lib/screens/financial_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/services/financial_service.dart';
import 'package:roozterfaceapp/widgets/expense_pie_chart.dart';
import 'package:roozterfaceapp/widgets/trend_chart.dart';

class FinancialDashboardScreen extends StatefulWidget {
  const FinancialDashboardScreen({super.key});

  @override
  State<FinancialDashboardScreen> createState() =>
      _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> {
  final FinancialService _financialService = FinancialService();

  DateTime? _startDate;
  DateTime? _endDate;

  Future<FinancialSummary>? _summaryFuture;
  // --- VARIABLES PARA NUEVOS GRÁFICOS ---
  Future<List<Map<String, dynamic>>>? _monthlyFuture;
  Future<Map<String, double>>? _breakdownFuture;

  @override
  void initState() {
    super.initState();
    // Inicializamos con el mes actual por defecto
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    _loadSummary();
  }

  void _loadSummary() {
    final activeGalleraId =
        Provider.of<UserDataProvider>(context, listen: false)
            .userProfile
            ?.activeGalleraId;
    if (activeGalleraId != null && _startDate != null && _endDate != null) {
      setState(() {
        _summaryFuture = _financialService.getFinancialSummary(
          galleraId: activeGalleraId,
          startDate: _startDate!,
          endDate: _endDate!,
        );
        // Cargar datos para gráficos
        _monthlyFuture = _financialService.getMonthlyFinancials(
            galleraId: activeGalleraId, year: _startDate!.year);
        _breakdownFuture = _financialService.getExpenseCategoryBreakdown(
            galleraId: activeGalleraId,
            startDate: _startDate!,
            endDate: _endDate!);
      });
    }
  }

  Future<void> _selectDate(BuildContext context,
      {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        // Recargamos el resumen con el nuevo rango de fechas
        _loadSummary();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeGalleraId =
        Provider.of<UserDataProvider>(context, listen: false)
            .userProfile
            ?.activeGalleraId;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Financiero'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Resumen'),
              Tab(text: 'Tendencias'),
              Tab(text: 'Desglose'),
            ],
          ),
        ),
        body: activeGalleraId == null
            ? const Center(child: Text('No hay gallera activa.'))
            : Column(
                children: [
                  _buildDateFilter(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildSummaryTab(),
                        _buildTrendsTab(),
                        _buildBreakdownTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    return FutureBuilder<FinancialSummary>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final summary = snapshot.data ?? FinancialSummary();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSummaryCard('Ingresos Totales', summary.totalIncome,
                  Colors.green, Icons.arrow_upward),
              _buildSummaryCard('Gastos Totales', summary.totalExpenses,
                  Colors.red, Icons.arrow_downward),
              _buildBalanceCard(summary.netBalance),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _monthlyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        // Importar localmente para evitar errores si no se ha importado arriba
        // (Aunque lo ideal es importar arriba, aquí lo hacemos dinámico)
        // Asumimos que TrendChart ya está importado o lo importaremos
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Ingresos vs Gastos (Año Actual)",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(child: TrendChart(monthlyData: snapshot.data ?? [])),
          ],
        );
      },
    );
  }

  Widget _buildBreakdownTab() {
    return FutureBuilder<Map<String, double>>(
      future: _breakdownFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Distribución de Gastos",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(child: ExpensePieChart(categoryData: snapshot.data ?? {})),
          ],
        );
      },
    );
  }

  Widget _buildDateFilter() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
              child: InkWell(
            onTap: () => _selectDate(context, isStartDate: true),
            child: InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'Desde', border: OutlineInputBorder()),
              child: Text(_startDate != null
                  ? dateFormat.format(_startDate!)
                  : 'Seleccionar'),
            ),
          )),
          const SizedBox(width: 8),
          Expanded(
              child: InkWell(
            onTap: () => _selectDate(context, isStartDate: false),
            child: InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'Hasta', border: OutlineInputBorder()),
              child: Text(_endDate != null
                  ? dateFormat.format(_endDate!)
                  : 'Seleccionar'),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, double amount, Color color, IconData icon) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 36),
        title: Text(title, style: theme.textTheme.titleMedium),
        trailing: Text(
          NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(amount),
          style: theme.textTheme.headlineSmall
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    final theme = Theme.of(context);
    final isProfit = balance >= 0;
    final color = isProfit ? Colors.green.shade800 : Colors.red.shade800;

    return Card(
        color: color.withOpacity(0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('BALANCE NETO (PERÍODO)',
                  style: theme.textTheme.titleLarge?.copyWith(color: color)),
              const SizedBox(height: 8),
              Text(
                NumberFormat.currency(locale: 'es_MX', symbol: '\$')
                    .format(balance),
                style: theme.textTheme.displayMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              )
            ],
          ),
        ));
  }
}
