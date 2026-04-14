// lib/services/tournament_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roozterfaceapp/models/tournament_model.dart';
import 'package:roozterfaceapp/models/tournament_participant.dart';

class TournamentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _tournamentsCollection => _firestore.collection('tournaments');

  // --- GESTIÓN DE TORNEOS ---

  Future<String> createTournament(TournamentModel tournament) async {
    DocumentReference ref = await _tournamentsCollection.add(tournament.toMap());
    return ref.id;
  }

  Stream<List<TournamentModel>> getActiveTournaments() {
    return _tournamentsCollection
        .where('status', isNotEqualTo: 'finalizado')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => TournamentModel.fromFirestore(doc)).toList());
  }

  // --- GESTIÓN DE PARTICIPANTES ---

  Future<void> addParticipant(String tournamentId, TournamentParticipant participant) async {
    await _tournamentsCollection
        .doc(tournamentId)
        .collection('participants')
        .add(participant.toMap());
    
    // Añadimos a la lista cacheada en el documento principal
    await _tournamentsCollection.doc(tournamentId).update({
      'participants': FieldValue.arrayUnion([participant.partidoId])
    });
  }

  Stream<List<TournamentParticipant>> getParticipantsStream(String tournamentId) {
    return _tournamentsCollection
        .doc(tournamentId)
        .collection('participants')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => TournamentParticipant.fromFirestore(doc)).toList());
  }

  // --- ALGORITMO DE COTEJO (MATCHING) ---

  /// Busca oponentes potenciales para un ave específica dentro de un torneo.
  /// Sigue las reglas de:
  /// 1. Tolerancia de peso (weightTolerance).
  /// 2. No pelear contra el mismo Partido.
  /// 3. Respetar Pactos (opcional en esta fase).
  Future<List<Map<String, dynamic>>> findCotejoMatches({
    required String tournamentId,
    required String myPartidoId,
    required int myBirdWeight,
    required int tolerance,
  }) async {
    final participantsSnap = await _tournamentsCollection.doc(tournamentId).collection('participants').get();
    
    List<Map<String, dynamic>> potentialMatches = [];

    for (var doc in participantsSnap.docs) {
      final participant = TournamentParticipant.fromFirestore(doc);
      
      // Regla: No pelear contra uno mismo
      if (participant.partidoId == myPartidoId) continue;

      for (var bird in participant.birds) {
        // Solo aves pendientes de pelea
        if (bird.status != 'Pendiente') continue;

        // Regla: Tolerancia de peso
        int weightDiff = (bird.weight - myBirdWeight).abs();
        if (weightDiff <= tolerance) {
          potentialMatches.add({
            'participant': participant,
            'bird': bird,
            'weightDiff': weightDiff,
          });
        }
      }
    }

    // Ordenamos por menor diferencia de peso
    potentialMatches.sort((a, b) => (a['weightDiff'] as int).compareTo(b['weightDiff'] as int));

    return potentialMatches;
  }

  // --- GESTIÓN DE RESULTADOS Y RANKING ---

  /// Actualiza los puntos y el Tiempo de Fondo de un participante tras un combate.
  Future<void> updateParticipantStats({
    required String tournamentId,
    required String participantDocId,
    required int pointsToAdd,
    required int secondsToAdd,
  }) async {
    await _tournamentsCollection
        .doc(tournamentId)
        .collection('participants')
        .doc(participantDocId)
        .update({
      'totalPoints': FieldValue.increment(pointsToAdd),
      'totalTimeSeconds': FieldValue.increment(secondsToAdd),
    });
  }
}
