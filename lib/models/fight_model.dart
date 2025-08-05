// lib/models/fight_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FightModel {
  final String id;
  final DateTime date;
  final String location; // Lugar o Derby
  final String opponent; // Placa o descripción del oponente
  final String result; // "Victoria", "Derrota", "Tabla"
  final String notes; // Observaciones sobre la pelea

  FightModel({
    required this.id,
    required this.date,
    required this.location,
    required this.opponent,
    required this.result,
    required this.notes,
  });

  factory FightModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FightModel(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      opponent: data['opponent'] ?? '',
      result: data['result'] ?? 'No registrado',
      notes: data['notes'] ?? '',
    );
  }
}
