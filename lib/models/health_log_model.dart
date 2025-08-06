// lib/models/health_log_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class HealthLogModel {
  final String id;
  final DateTime date;
  final String
  logCategory; // "Enfermedad/Tratamiento", "Vacunación", "Desparasitación", "Suplemento/Vitamina"
  final String productName; // Nombre del producto: "Tylan", "Complejo B", etc.
  final String? illnessOrCondition; // "Corisa", "Herida", etc. (Opcional)
  final String? dosage; // "0.5 ml", "1 pastilla" (Opcional)
  final String notes;

  HealthLogModel({
    required this.id,
    required this.date,
    required this.logCategory,
    required this.productName,
    this.illnessOrCondition,
    this.dosage,
    required this.notes,
  });

  factory HealthLogModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HealthLogModel(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      logCategory: data['logCategory'] ?? 'Otro',
      productName: data['productName'] ?? 'No especificado',
      illnessOrCondition: data['illnessOrCondition'],
      dosage: data['dosage'],
      notes: data['notes'] ?? '',
    );
  }
}
