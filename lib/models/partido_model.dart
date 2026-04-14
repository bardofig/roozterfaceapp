// lib/models/partido_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PartidoModel {
  final String id;
  final String name;
  final String? logoUrl;
  final String ownerId;
  final Map<String, String> members; // Map<uid, role>
  final DateTime createdAt;

  // --- ESTADÍSTICAS PARA LEADERBOARD ---
  final int totalFights;
  final int wins;
  final int losses;
  final int draws;
  final int lostRoosters;

  PartidoModel({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.ownerId,
    required this.members,
    required this.createdAt,
    this.totalFights = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.lostRoosters = 0,
  });

  factory PartidoModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PartidoModel(
      id: doc.id,
      name: data['name'] ?? 'Sin Nombre',
      logoUrl: data['logoUrl'],
      ownerId: data['ownerId'] ?? '',
      members: Map<String, String>.from(data['members'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalFights: data['totalFights'] ?? 0,
      wins: data['wins'] ?? 0,
      losses: data['losses'] ?? 0,
      draws: data['draws'] ?? 0,
      lostRoosters: data['lostRoosters'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'ownerId': ownerId,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
      'totalFights': totalFights,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'lostRoosters': lostRoosters,
    };
  }
}
