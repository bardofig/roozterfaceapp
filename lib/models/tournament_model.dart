// lib/models/tournament_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum TournamentStatus { programado, pesando, enProgreso, finalizado }

class TournamentModel {
  final String id;
  final String name;
  final DateTime date;
  final String type; // 'Derby', 'Individual', 'Round Robin'
  final int birdsPerEntry; 
  final double entryFee;
  final double posta;
  final int weightTolerance; // en gramos (ej: 60)
  final TournamentStatus status;
  final Map<String, int> pointsConfig; // {'win': 3, 'draw': 1, 'loss': 0}
  final String organizerId;
  final List<String> participants; // IDs de Partidos inscritos
  final Map<String, List<String>> pacts; // partidoId -> [partidoIds aliados]

  TournamentModel({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    required this.birdsPerEntry,
    required this.entryFee,
    required this.posta,
    this.weightTolerance = 60,
    required this.status,
    required this.pointsConfig,
    required this.organizerId,
    this.participants = const [],
    this.pacts = const {},
  });

  factory TournamentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TournamentModel(
      id: doc.id,
      name: data['name'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] ?? 'Derby',
      birdsPerEntry: data['birdsPerEntry'] ?? 4,
      entryFee: (data['entryFee'] ?? 0.0).toDouble(),
      posta: (data['posta'] ?? 0.0).toDouble(),
      weightTolerance: data['weightTolerance'] ?? 60,
      status: TournamentStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'programado'),
        orElse: () => TournamentStatus.programado,
      ),
      pointsConfig: Map<String, int>.from(data['pointsConfig'] ?? {'win': 3, 'draw': 1, 'loss': 0}),
      organizerId: data['organizerId'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      pacts: (data['pacts'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ) ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': Timestamp.fromDate(date),
      'type': type,
      'birdsPerEntry': birdsPerEntry,
      'entryFee': entryFee,
      'posta': posta,
      'weightTolerance': weightTolerance,
      'status': status.name,
      'pointsConfig': pointsConfig,
      'organizerId': organizerId,
      'participants': participants,
      'pacts': pacts,
    };
  }
}
