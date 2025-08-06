// lib/services/fight_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roozterfaceapp/models/fight_model.dart';

class FightService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Obtiene una referencia a la sub-sub-colección de peleas
  CollectionReference _fightsCollection(String roosterId) {
    if (currentUserId == null) throw Exception("Usuario no autenticado.");
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('gallos')
        .doc(roosterId)
        .collection('fights');
  }

  // Obtiene una referencia al documento principal del gallo
  DocumentReference _roosterDocument(String roosterId) {
    if (currentUserId == null) throw Exception("Usuario no autenticado.");
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('gallos')
        .doc(roosterId);
  }

  // Obtiene la lista de peleas para un gallo específico en tiempo real.
  Stream<List<FightModel>> getFightsStream(String roosterId) {
    return _fightsCollection(
      roosterId,
    ).orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FightModel.fromFirestore(doc)).toList();
    });
  }

  // Crea un evento de combate con estado "Programado"
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
      };
      await _fightsCollection(roosterId).add(fightData);
    } catch (e) {
      throw Exception("Ocurrió un error al programar el combate.");
    }
  }

  // Actualiza un evento de combate y, si es necesario, el estado general del gallo.
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
  }) async {
    try {
      // Usamos una transacción para asegurar que ambas escrituras (si son necesarias)
      // se completen de forma atómica.
      await _firestore.runTransaction((transaction) async {
        DocumentReference fightDocRef = _fightsCollection(
          roosterId,
        ).doc(fightId);
        DocumentReference roosterDocRef = _roosterDocument(roosterId);

        // Leemos el estado actual del gallo ANTES de hacer cambios.
        DocumentSnapshot roosterSnapshot = await transaction.get(roosterDocRef);
        if (!roosterSnapshot.exists) {
          throw Exception("El gallo no existe.");
        }
        String currentRoosterStatus = roosterSnapshot.get('status');

        // Preparamos los datos para actualizar el registro de la pelea
        Map<String, dynamic> fightData = {
          'date': Timestamp.fromDate(date),
          'location': location,
          'preparationNotes': preparationNotes,
          'status': 'Completado',
          'opponent': opponent,
          'result': result,
          'postFightNotes': postFightNotes,
          'survived': survived,
        };

        // 1. Programamos la actualización del documento de la pelea
        transaction.update(fightDocRef, fightData);

        // 2. Programamos la actualización del estado del gallo, si es necesario
        if (!survived) {
          // Si no sobrevivió, forzamos el estado a 'Perdido en Combate'
          transaction.update(roosterDocRef, {'status': 'Perdido en Combate'});
        } else {
          // Si SÍ sobrevivió, PERO su estado actual era 'Perdido en Combate'
          // (lo que significa que estamos corrigiendo un error), lo revertimos a 'Descansando'.
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

  // Borra un evento de combate
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
