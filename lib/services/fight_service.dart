// lib/services/fight_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roozterfaceapp/models/fight_model.dart';

class FightService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- CORREGIDO ---
  // Ahora apunta a la subcolección dentro de /galleras
  CollectionReference _fightsCollection(String galleraId, String roosterId) {
    return _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('gallos')
        .doc(roosterId)
        .collection('fights');
  }

  // --- CORREGIDO ---
  // Apunta al documento del gallo dentro de la gallera
  DocumentReference _roosterDocument(String galleraId, String roosterId) {
    return _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('gallos')
        .doc(roosterId);
  }

  // --- CORREGIDO ---
  // El stream ahora necesita la galleraId
  Stream<List<FightModel>> getFightsStream(String galleraId, String roosterId) {
    if (galleraId.isEmpty) return Stream.value([]);
    return _fightsCollection(
      galleraId,
      roosterId,
    ).orderBy('date', descending: true).snapshots().map((snapshot) {
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
      };
      await _fightsCollection(galleraId, roosterId).add(fightData);
    } catch (e) {
      throw Exception("Ocurrió un error al programar el combate.");
    }
  }

  Future<void> updateFight({
    required String galleraId, // Esencial para la ruta
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
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference fightDocRef = _fightsCollection(
          galleraId,
          roosterId,
        ).doc(fightId);
        DocumentReference roosterDocRef = _roosterDocument(
          galleraId,
          roosterId,
        ); // --- CORREGIDO ---

        DocumentSnapshot roosterSnapshot = await transaction.get(roosterDocRef);
        if (!roosterSnapshot.exists) {
          throw Exception("El gallo no existe.");
        }
        String currentRoosterStatus = roosterSnapshot.get('status');

        Map<String, dynamic> fightData = {
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
        };

        transaction.update(fightDocRef, fightData);

        if (!survived) {
          transaction.update(roosterDocRef, {'status': 'Perdido en Combate'});
        } else {
          if (currentRoosterStatus == 'Perdido en Combate') {
            transaction.update(roosterDocRef, {'status': 'Descansando'});
          }
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
      throw Exception("Ocurrió un error al borrar el evento.");
    }
  }
}
