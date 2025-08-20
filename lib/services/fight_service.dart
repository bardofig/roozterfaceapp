// lib/services/fight_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roozterfaceapp/models/fight_model.dart';

class FightService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- CORRECCIÓN DE CONSISTENCIA: 'gallos' -> 'roosters' ---
  // Se asume que el nombre de la colección en Firestore es 'roosters' para
  // mantener coherencia con el resto de la aplicación (ej. RoosterModel).
  CollectionReference _fightsCollection(String galleraId, String roosterId) {
    return _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('roosters')
        .doc(roosterId)
        .collection('fights');
  }

  // --- CORRECCIÓN DE CONSISTENCIA: 'gallos' -> 'roosters' ---
  DocumentReference _roosterDocument(String galleraId, String roosterId) {
    return _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('roosters')
        .doc(roosterId);
  }

  Stream<List<FightModel>> getFightsStream(String galleraId, String roosterId) {
    if (galleraId.isEmpty || roosterId.isEmpty) return Stream.value([]);
    return _fightsCollection(galleraId, roosterId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FightModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> addFight({
    required String galleraId,
    required String roosterId,
    required DateTime date,
    required String location,
    String? preparationNotes,
  }) async {
    try {
      Map<String, dynamic> fightData = {
        'galleraId': galleraId,
        'roosterId': roosterId,
        'date': Timestamp.fromDate(date),
        'location': location,
        'preparationNotes': preparationNotes,
        'status': 'Programado',
        'opponent': null,
        'result': null,
        'postFightNotes': null,
        'survived': null,
        'weaponType': null,
        'fightDuration': null,
        'injuriesSustained': null,
        'netProfit': null,
      };
      await _fightsCollection(galleraId, roosterId).add(fightData);
    } catch (e) {
      print("Error en FightService.addFight: $e");
      throw Exception("Ocurrió un error al programar el combate.");
    }
  }

  Future<void> updateFight({
    required String galleraId,
    required String roosterId,
    required String fightId,
    required DateTime date,
    required String location,
    String? preparationNotes,
    String? opponent,
    String? result,
    String? postFightNotes,
    required bool survived,
    String? weaponType,
    String? fightDuration,
    String? injuriesSustained,
    double? netProfit,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference fightDocRef =
            _fightsCollection(galleraId, roosterId).doc(fightId);
        DocumentReference roosterDocRef =
            _roosterDocument(galleraId, roosterId);

        DocumentSnapshot roosterSnapshot = await transaction.get(roosterDocRef);
        if (!roosterSnapshot.exists) throw Exception("El gallo no existe.");

        String currentRoosterStatus =
            (roosterSnapshot.data() as Map<String, dynamic>)['status'] ??
                'Activo';

        Map<String, dynamic> fightData = {
          'galleraId': galleraId,
          'roosterId': roosterId,
          'date': Timestamp.fromDate(date),
          'location': location,
          'preparationNotes': preparationNotes,
          'status': 'Completado',
          'opponent': opponent,
          'result': result,
          'postFightNotes': postFightNotes,
          'survived': survived,
          'weaponType': weaponType,
          'fightDuration': fightDuration,
          'injuriesSustained': injuriesSustained,
          'netProfit': netProfit,
        };

        transaction.update(fightDocRef, fightData);

        if (!survived) {
          transaction.update(roosterDocRef, {'status': 'Perdido en Combate'});
        } else if (currentRoosterStatus == 'Perdido en Combate') {
          // Si por error se marcó como no sobreviviente y se corrige, se le pone a descansar.
          transaction.update(roosterDocRef, {'status': 'Descansando'});
        }
      });
    } catch (e) {
      print("Error en la transacción de actualización de pelea: $e");
      throw Exception("Ocurrió un error al actualizar el resultado.");
    }
  }

  Future<void> deleteFight({
    required String galleraId,
    required String roosterId,
    required String fightId,
  }) async {
    try {
      await _fightsCollection(galleraId, roosterId).doc(fightId).delete();
    } catch (e) {
      print("Error en FightService.deleteFight: $e");
      throw Exception("Ocurrió un error al borrar el evento.");
    }
  }
}
