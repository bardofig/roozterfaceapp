// lib/screens/financial_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/services/financial_service.dart';
import 'package:roozterfaceapp/services/pdf_service.dart';
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

  Future<void> _exportToPdf() async {
    try {
      final summary = await _summaryFuture;
      final monthlyData = await _monthlyFuture;
      final breakdown = await _breakdownFuture;

      await PdfService().generateFinancialReportPdf(
        summary: summary ?? FinancialSummary(),
        monthlyData: monthlyData ?? [],
        categoryBreakdown: breakdown ?? {},
        galleraName: "Mi Gallera",
        startDate: _startDate!,
        endDate: _endDate!,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e'), backgroundColor: Colors.red),
        );
      }
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
          title: const Text('Análisis Financiero'),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Exportar Reporte',
              onPressed: _exportToPdf,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSummary,
            ),
          ],
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              _buildBalanceCard(summary.netBalance),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Ingresos',
                      summary.totalIncome,
                      [const Color(0xFF00B09B), const Color(0xFF96C93D)],
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Gastos',
                      summary.totalExpenses,
                      [const Color(0xFFEB3349), const Color(0xFFF45C43)],
                      Icons.trending_down,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSimpleStatTile('Ventas de Gallos', summary.totalSales, Icons.shopping_bag_outlined),
              _buildSimpleStatTile('Premios de Combates', summary.totalFightProfit, Icons.emoji_events_outlined),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, double amount, List<Color> colors, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(amount),
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    final theme = Theme.of(context);
    final isProfit = balance >= 0;
    final primaryColor = isProfit ? Colors.blue.shade700 : Colors.deepOrange.shade700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Text(
            'BALANCE NETO',
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Text(
            NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(balance),
            style: TextStyle(
              color: primaryColor,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isProfit ? 'GANANCIA' : 'PÉRDIDA',
              style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStatTile(String title, double amount, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.grey.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.blueGrey, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text(
          NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(amount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
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
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.analytics_outlined, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text("Rendimiento Mensual",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text("Comparativa de ingresos y gastos durante el año actual.",
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                margin: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: TrendChart(monthlyData: snapshot.data ?? []),
              ),
            ),
            const SizedBox(height: 20),
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
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.pie_chart_outline, color: Colors.orangeAccent),
                  SizedBox(width: 8),
                  Text("Distribución de Gastos",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
            Expanded(
              child: Card(
                margin: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ExpensePieChart(categoryData: snapshot.data ?? {}),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateFilter() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
              child: InkWell(
            onTap: () => _selectDate(context, isStartDate: true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Text(_startDate != null ? dateFormat.format(_startDate!) : 'Inicio', 
                       style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          )),
          const SizedBox(width: 8),
          const Text('→', style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
              child: InkWell(
            onTap: () => _selectDate(context, isStartDate: false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Text(_endDate != null ? dateFormat.format(_endDate!) : 'Fin',
                       style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}
