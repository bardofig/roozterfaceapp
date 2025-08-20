// lib/services/expense_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roozterfaceapp/models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _expensesCollection(String galleraId) {
    return _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('expenses');
  }

  /// --- MÉTODO MODIFICADO PARA ACEPTAR RANGO DE FECHAS ---
  /// Obtiene un stream de gastos de una gallera, opcionalmente filtrados por fecha.
  Stream<List<ExpenseModel>> getExpensesStream({
    required String galleraId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (galleraId.isEmpty) {
      return Stream.value([]);
    }

    // Empezamos con la consulta base, ordenada por fecha
    Query query =
        _expensesCollection(galleraId).orderBy('expenseDate', descending: true);

    // Si se proporciona una fecha de inicio, la añadimos a la consulta
    if (startDate != null) {
      query = query.where('expenseDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    // Si se proporciona una fecha de fin, la añadimos a la consulta
    if (endDate != null) {
      // Para incluir el día completo, nos aseguramos de que sea hasta el final del día
      DateTime endOfDay =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query = query.where('expenseDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList());
  }

  /// Añade un nuevo registro de gasto a la gallera.
  Future<void> addExpense({
    required String galleraId,
    required DateTime date,
    required String category,
    required String description,
    required double amount,
  }) async {
    if (description.trim().isEmpty || amount <= 0) {
      throw Exception('La descripción y un monto válido son requeridos.');
    }
    final newExpense = {
      'expenseDate': Timestamp.fromDate(date),
      'category': category,
      'description': description,
      'amount': amount,
    };
    await _expensesCollection(galleraId).add(newExpense);
  }

  /// Elimina un registro de gasto.
  Future<void> deleteExpense({
    required String galleraId,
    required String expenseId,
  }) async {
    await _expensesCollection(galleraId).doc(expenseId).delete();
  }
}
