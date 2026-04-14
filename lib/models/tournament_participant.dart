// lib/models/tournament_participant.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TournamentBird {
  final String roosterId;
  final String ringNumber;
  final int weight; // en gramos
  final String status; // 'Pendiente', 'Cotejado', 'Peleó'
  final String? fightId; // Link al combate generado

  TournamentBird({
    required this.roosterId,
    required this.ringNumber,
    required this.weight,
    this.status = 'Pendiente',
    this.fightId,
  });

  Map<String, dynamic> toMap() {
    return {
      'roosterId': roosterId,
      'ringNumber': ringNumber,
      'weight': weight,
      'status': status,
      'fightId': fightId,
    };
  }

  factory TournamentBird.fromMap(Map<String, dynamic> map) {
    return TournamentBird(
      roosterId: map['roosterId'] ?? '',
      ringNumber: map['ringNumber'] ?? '',
      weight: map['weight'] ?? 0,
      status: map['status'] ?? 'Pendiente',
      fightId: map['fightId'],
    );
  }
}

class TournamentParticipant {
  final String id;
  final String tournamentId;
  final String partidoId;
  final String partidoName;
  final List<TournamentBird> birds;
  final int totalPoints;
  final int totalTimeSeconds; // Tiempo de Fondo acumulado (para desempate)

  TournamentParticipant({
    required this.id,
    required this.tournamentId,
    required this.partidoId,
    required this.partidoName,
    required this.birds,
    this.totalPoints = 0,
    this.totalTimeSeconds = 0,
  });

  factory TournamentParticipant.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TournamentParticipant(
      id: doc.id,
      tournamentId: data['tournamentId'] ?? '',
      partidoId: data['partidoId'] ?? '',
      partidoName: data['partidoName'] ?? '',
      birds: (data['birds'] as List? ?? [])
          .map((b) => TournamentBird.fromMap(Map<String, dynamic>.from(b)))
          .toList(),
      totalPoints: data['totalPoints'] ?? 0,
      totalTimeSeconds: data['totalTimeSeconds'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tournamentId': tournamentId,
      'partidoId': partidoId,
      'partidoName': partidoName,
      'birds': birds.map((b) => b.toMap()).toList(),
      'totalPoints': totalPoints,
      'totalTimeSeconds': totalTimeSeconds,
    };
  }
}
