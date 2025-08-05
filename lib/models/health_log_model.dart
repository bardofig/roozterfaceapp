// lib/models/health_log_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class HealthLogModel {
  final String id;
  final DateTime date;
  final String
  logType; // "Vacunación", "Desparasitación", "Vitamina", "Tratamiento"
  final String description; // Nombre del producto o descripción del tratamiento
  final String notes;

  HealthLogModel({
    required this.id,
    required this.date,
    required this.logType,
    required this.description,
    required this.notes,
  });

  factory HealthLogModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HealthLogModel(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      logType: data['logType'] ?? 'Desconocido',
      description: data['description'] ?? '',
      notes: data['notes'] ?? '',
    );
  }
}
