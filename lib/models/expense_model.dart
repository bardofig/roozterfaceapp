// lib/models/expense_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final Timestamp expenseDate;
  final String category;
  final String description;
  final double amount;

  ExpenseModel({
    required this.id,
    required this.expenseDate,
    required this.category,
    required this.description,
    required this.amount,
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      expenseDate: data['expenseDate'] ?? Timestamp.now(),
      category: data['category'] ?? 'Otro',
      description: data['description'] ?? '',
      amount: (data['amount'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expenseDate': expenseDate,
      'category': category,
      'description': description,
      'amount': amount,
    };
  }
}
