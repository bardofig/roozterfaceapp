// lib/models/fight_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FightModel {
  final String id;
  final DateTime date;
  final String location;
  final String status;

  final String? opponent;
  final String? result;

  final String? preparationNotes;
  final String? postFightNotes;

  // --- ¡NUEVO CAMPO CRUCIAL! ---
  // Guardará 'true' o 'false'. Será nulo si la pelea está solo 'Programada'.
  final bool? survived;

  FightModel({
    required this.id,
    required this.date,
    required this.location,
    required this.status,
    this.opponent,
    this.result,
    this.preparationNotes,
    this.postFightNotes,
    this.survived, // Lo añadimos al constructor
  });

  factory FightModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FightModel(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      status: data['status'] ?? 'Programado',
      opponent: data['opponent'],
      result: data['result'],
      preparationNotes: data['preparationNotes'],
      postFightNotes: data['postFightNotes'],
      survived: data['survived'], // Leemos el nuevo campo desde Firestore
    );
  }
}
