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
}
