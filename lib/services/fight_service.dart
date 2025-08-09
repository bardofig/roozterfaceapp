// lib/services/fight_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roozterfaceapp/models/fight_model.dart';

class FightService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference _fightsCollection(String roosterId) {
    if (currentUserId == null) throw Exception("Usuario no autenticado.");
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('gallos')
        .doc(roosterId)
        .collection('fights');
  }

  DocumentReference _roosterDocument(String roosterId) {
    if (currentUserId == null) throw Exception("Usuario no autenticado.");
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('gallos')
        .doc(roosterId);
  }

  Stream<List<FightModel>> getFightsStream(String roosterId) {
    return _fightsCollection(
      roosterId,
    ).orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FightModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> addFight({
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
      await _fightsCollection(roosterId).add(fightData);
    } catch (e) {
      throw Exception("Ocurrió un error al programar el combate.");
    }
  }

  // --- ¡MÉTODO UPDATEFIGHT CORREGIDO Y COMPLETO! ---
  Future<void> updateFight({
    required String roosterId,
    required String fightId,
    required DateTime date,
    required String location,
    String? preparationNotes,
    String? opponent,
    String? result,
    String? postFightNotes,
    required bool survived,
    // --- ¡PARÁMETROS AÑADIDOS! ---
    String? weaponType,
    String? fightDuration,
    String? injuriesSustained,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference fightDocRef = _fightsCollection(
          roosterId,
        ).doc(fightId);
        DocumentReference roosterDocRef = _roosterDocument(roosterId);

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
          // --- DATOS A GUARDAR ---
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
    required String roosterId,
    required String fightId,
  }) async {
    try {
      await _fightsCollection(roosterId).doc(fightId).delete();
    } catch (e) {
      throw Exception("Ocurrió un error al borrar el evento.");
    }
  }
}
