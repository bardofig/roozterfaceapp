// lib/services/expense_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:roozterfaceapp/models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Obtiene un stream de gastos de la subcolección de transacciones de una gallera.
  Stream<List<ExpenseModel>> getExpensesStream({
    required String galleraId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (galleraId.isEmpty) {
      return Stream.value([]);
    }

    // --- RUTA MODIFICADA: Apunta a la subcolección y elimina el 'where' de galleraId ---
    Query query = _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('transactions')
        .where('type', isEqualTo: 'gasto')
        .orderBy('date', descending: true);

    if (startDate != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      DateTime endOfDay =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query = query.where('date',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }

    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Mapeamos del documento de transacción al modelo de gasto
          return ExpenseModel(
            id: doc.id,
            expenseDate: data['date'] ?? Timestamp.now(),
            category: data['category'] ?? 'Otro',
            description: data['description'] ?? '',
            amount: (data['amount'] as num? ?? 0.0).toDouble(),
          );
        }).toList());
  }

  /// Llama a una Cloud Function para añadir un nuevo registro de gasto.
  Future<void> addExpense({
    required String galleraId,
    required DateTime date,
    required String category,
    required String description,
    required double amount,
  }) async {
    try {
      final callable = _functions.httpsCallable('addExpenseTransaction');
      await callable.call({
        'galleraId': galleraId,
        'date': date.toIso8601String(),
        'category': category,
        'description': description,
        'amount': amount,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? "Error al comunicarse con el servidor.");
    } catch (e) {
      throw Exception("Ocurrió un error inesperado al registrar el gasto.");
    }
  }

  /// Llama a una Cloud Function para actualizar un gasto existente.
  Future<void> updateExpense({
    required String galleraId,
    required String expenseId,
    required DateTime date,
    required String category,
    required String description,
    required double amount,
  }) async {
    try {
      final callable = _functions.httpsCallable('updateExpenseTransaction');
      await callable.call({
        'transactionId': expenseId,
        'galleraId': galleraId,
        'date': date.toIso8601String(),
        'category': category,
        'description': description,
        'amount': amount,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? "Error al comunicarse con el servidor.");
    } catch (e) {
      throw Exception("Ocurrió un error inesperado al actualizar el gasto.");
    }
  }

  /// Llama a una Cloud Function para eliminar un registro de gasto.
  Future<void> deleteExpense({
    required String galleraId,
    required String expenseId,
  }) async {
    try {
      final callable = _functions.httpsCallable('deleteTransaction');
      await callable.call({
        'transactionId': expenseId,
        'galleraId': galleraId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? "Error al comunicarse con el servidor.");
    } catch (e) {
      throw Exception("Ocurrió un error inesperado al eliminar el gasto.");
    }
  }
}
