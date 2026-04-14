// lib/services/financial_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FinancialSummary {
  final double totalSales;
  final double totalFightProfit;
  final double totalIncome;
  final double totalExpenses;
  final double netBalance;

  FinancialSummary({
    this.totalSales = 0.0,
    this.totalFightProfit = 0.0,
    this.totalIncome = 0.0,
    this.totalExpenses = 0.0,
    this.netBalance = 0.0,
  });
}

class FinancialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene el resumen financiero consultando la subcolección de transacciones de una gallera.
  Future<FinancialSummary> getFinancialSummary({
    required String galleraId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (galleraId.isEmpty) {
      return FinancialSummary();
    }

    final endOfDay =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // --- RUTA MODIFICADA: Ahora apunta a la subcolección ---
    final transactionsRef = _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('transactions');

    // --- CONSULTA 1: INGRESOS ---
    final incomeQuery = await transactionsRef
        // El filtro 'galleraId' ya no es necesario aquí
        .where('type', isEqualTo: 'ingreso')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .get();

    double totalSales = 0.0;
    double totalFightProfit = 0.0;

    for (var doc in incomeQuery.docs) {
      final data = doc.data(); // No es necesario el cast a Map
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      if (data['category'] == 'venta') {
        totalSales += amount;
      } else if (data['category'] == 'combate') {
        // En ingresos, el 'amount' de un combate es siempre positivo
        totalFightProfit += amount;
      }
    }

    // --- CONSULTA 2: GASTOS ---
    final expensesQuery = await transactionsRef
        .where('type', isEqualTo: 'gasto')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .get();

    double totalExpensesFromGeneral = 0.0;

    for (var doc in expensesQuery.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      // Sumamos todos los gastos, incluyendo los de combate (que ya son positivos)
      totalExpensesFromGeneral += amount;
      // Si queremos desglosar el profit/loss de combates, lo restamos del ingreso
      if (data['category'] == 'combate') {
        totalFightProfit -= amount;
      }
    }

    // --- CÁLCULOS FINALES ---
    final double totalIncome =
        totalSales + (totalFightProfit > 0 ? totalFightProfit : 0);
    final double totalExpenses = totalExpensesFromGeneral;
    final double netBalance = totalIncome - totalExpenses;

    return FinancialSummary(
      totalSales: totalSales,
      totalFightProfit: totalFightProfit, // Esto puede ser negativo ahora
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netBalance: netBalance,
    );
  }
  // --- NUEVOS MÉTODOS PARA DASHBOARD ---

  /// Obtiene datos financieros agrupados por mes para un año específico
  Future<List<Map<String, dynamic>>> getMonthlyFinancials({
    required String galleraId,
    required int year,
  }) async {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31, 23, 59, 59);

    final transactionsRef = _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('transactions');

    final querySnapshot = await transactionsRef
        .where('date', isGreaterThanOrEqualTo: startOfYear)
        .where('date', isLessThanOrEqualTo: endOfYear)
        .get();

    // Inicializar mapa de meses (1-12)
    Map<int, Map<String, double>> monthlyData = {};
    for (int i = 1; i <= 12; i++) {
      monthlyData[i] = {'income': 0.0, 'expense': 0.0};
    }

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final type = data['type'] as String?;
      final month = date.month;

      if (type == 'ingreso') {
        monthlyData[month]!['income'] = monthlyData[month]!['income']! + amount;
      } else if (type == 'gasto') {
        monthlyData[month]!['expense'] =
            monthlyData[month]!['expense']! + amount;
      }
    }

    // Convertir a lista ordenada
    List<Map<String, dynamic>> result = [];
    monthlyData.forEach((month, values) {
      result.add({
        'month': month,
        'income': values['income'],
        'expense': values['expense'],
      });
    });

    return result;
  }

  /// Obtiene el desglose de gastos por categoría
  Future<Map<String, double>> getExpenseCategoryBreakdown({
    required String galleraId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final endOfDay =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final transactionsRef = _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('transactions');

    final querySnapshot = await transactionsRef
        .where('type', isEqualTo: 'gasto')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .get();

    Map<String, double> breakdown = {};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final category = data['category'] as String? ?? 'Otros';
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

      if (breakdown.containsKey(category)) {
        breakdown[category] = breakdown[category]! + amount;
      } else {
        breakdown[category] = amount;
      }
    }

    return breakdown;
  }

  /// Registra una nueva transacción (ingreso o gasto) en la gallera.
  Future<void> addTransaction({
    required String galleraId,
    required String type, // 'ingreso' o 'gasto'
    required String category,
    required double amount,
    required String description,
    required DateTime date,
    String? relatedId, // ID del gallo, combate, etc.
  }) async {
    if (galleraId.isEmpty) return;

    final transactionData = {
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
      'relatedId': relatedId,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('transactions')
        .add(transactionData);
  }
}
