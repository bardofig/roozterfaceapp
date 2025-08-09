// lib/models/fight_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FightModel {
  final String id;
  final DateTime date;
  final String location;
  final String status;

  final String? opponent;
  final String? result;
  final bool? survived;

  final String? preparationNotes;
  final String? postFightNotes;

  // --- ¡NUEVOS CAMPOS ENRIQUECIDOS! ---
  final String? weaponType;
  final String? fightDuration;
  final String? injuriesSustained;

  FightModel({
    required this.id,
    required this.date,
    required this.location,
    required this.status,
    this.opponent,
    this.result,
    this.survived,
    this.preparationNotes,
    this.postFightNotes,
    this.weaponType,
    this.fightDuration,
    this.injuriesSustained,
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
      survived: data['survived'],
      preparationNotes: data['preparationNotes'],
      postFightNotes: data['postFightNotes'],
      weaponType: data['weaponType'],
      fightDuration: data['fightDuration'],
      injuriesSustained: data['injuriesSustained'],
    );
  }
}
