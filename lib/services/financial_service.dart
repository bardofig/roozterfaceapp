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

  CollectionReference _roostersCollection(String galleraId) =>
      _firestore.collection('galleras').doc(galleraId).collection('gallos');
  CollectionReference _expensesCollection(String galleraId) =>
      _firestore.collection('galleras').doc(galleraId).collection('expenses');

  Future<FinancialSummary> getFinancialSummary({
    required String galleraId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final endOfDay =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // --- 1. Calcular Ingresos por Ventas (Esta consulta es correcta y permitida) ---
    final salesQuery = await _roostersCollection(galleraId)
        .where('status', isEqualTo: 'Vendido')
        .where('saleDate', isGreaterThanOrEqualTo: startDate)
        .where('saleDate', isLessThanOrEqualTo: endOfDay)
        .get();

    final double totalSales = salesQuery.docs.fold(0.0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      return sum + ((data['salePrice'] as num?)?.toDouble() ?? 0.0);
    });

    // --- 2. Calcular Ganancias/Pérdidas por Combates (Lógica Segura, sin Collection Group) ---
    double totalFightProfit = 0.0;
    final allRoostersSnapshot = await _roostersCollection(galleraId).get();

    for (final roosterDoc in allRoostersSnapshot.docs) {
      // Para cada gallo, consultamos su subcolección de peleas. Esto está permitido por tus reglas.
      final fightsQuery = await roosterDoc.reference
          .collection('fights')
          .where('status', isEqualTo: 'Completado')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .get();

      if (fightsQuery.docs.isNotEmpty) {
        // Sumamos el resultado de las peleas de este gallo al total.
        final profitForThisRooster = fightsQuery.docs.fold(0.0, (sum, doc) {
          final data = doc.data(); // El cast no es necesario aquí.
          return sum + ((data['netProfit'] as num?)?.toDouble() ?? 0.0);
        });
        totalFightProfit += profitForThisRooster;
      }
    }

    // --- 3. Calcular Gastos Totales (Esta consulta es correcta y permitida) ---
    final expensesQuery = await _expensesCollection(galleraId)
        .where('expenseDate', isGreaterThanOrEqualTo: startDate)
        .where('expenseDate', isLessThanOrEqualTo: endOfDay)
        .get();

    final double totalExpenses = expensesQuery.docs.fold(0.0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      return sum + ((data['amount'] as num?)?.toDouble() ?? 0.0);
    });

    // --- 4. Calcular los Totales Finales ---
    final double totalIncome = totalSales + totalFightProfit;
    final double netBalance = totalIncome - totalExpenses;

    return FinancialSummary(
      totalSales: totalSales,
      totalFightProfit: totalFightProfit,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netBalance: netBalance,
    );
  }
}
