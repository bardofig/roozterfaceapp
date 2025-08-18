// lib/services/expense_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roozterfaceapp/models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Apunta a la subcolección de gastos dentro de una gallera específica.
  CollectionReference _expensesCollection(String galleraId) {
    return _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('expenses');
  }

  /// Obtiene un stream de todos los gastos de una gallera, ordenados por fecha.
  Stream<List<ExpenseModel>> getExpensesStream(String galleraId) {
    if (galleraId.isEmpty) {
      return Stream.value([]);
    }
    return _expensesCollection(galleraId)
        .orderBy('expenseDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList());
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
