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

  final double? netProfit; // Ganancia o pérdida neta del evento
  final String? partidoId; // ✅ NUEVO: ID del partido
  final String? tournamentId; // ✅ NUEVO: ID del torneo
  final int? fightTimeSeconds; // ✅ NUEVO: Duración para Tiempo de Fondo
  final String? weaponType; // Ej: Navaja de pulgada, Espuela
  final String? weaponLength; // Ej: 1", 1 1/4"
  final String? weaponMaterial; // Ej: Acero al carbono
  final String? injuriesSustained;
  final String? fightDuration; // ✅ RESTAURADO: Campo legado/texto libre

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
    this.netProfit,
    this.partidoId,
    this.tournamentId,
    this.fightTimeSeconds,
    this.weaponType,
    this.weaponLength,
    this.weaponMaterial,
    this.injuriesSustained,
    this.fightDuration,
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
      netProfit: (data['netProfit'] ?? 0.0).toDouble(),
      partidoId: data['partidoId'],
      tournamentId: data['tournamentId'],
      fightTimeSeconds: data['fightTimeSeconds'],
      weaponType: data['weaponType'] ?? data['weapon_type'],
      weaponLength: data['weaponLength'],
      weaponMaterial: data['weaponMaterial'],
      injuriesSustained: data['injuriesSustained'] ?? data['injuries_sustained'],
      fightDuration: data['fightDuration'],
    );
  }

  /// Convierte el modelo a un mapa para escritura en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'location': location,
      'status': status,
      'opponent': opponent,
      'result': result,
      'survived': survived,
      'preparationNotes': preparationNotes,
      'postFightNotes': postFightNotes,
      'netProfit': netProfit,
      'partidoId': partidoId,
      'tournamentId': tournamentId,
      'fightTimeSeconds': fightTimeSeconds,
      'weaponType': weaponType,
      'weaponLength': weaponLength,
      'weaponMaterial': weaponMaterial,
      'injuriesSustained': injuriesSustained,
      'fightDuration': fightDuration,
    };
  }
}
