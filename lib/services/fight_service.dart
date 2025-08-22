// lib/services/fight_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:roozterfaceapp/models/fight_model.dart';

class FightService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // --- ¡NUEVO! Instancia de Cloud Functions ---
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  CollectionReference _fightsCollection(String galleraId, String roosterId) {
    return _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('gallos')
        .doc(roosterId)
        .collection('fights');
  }

  DocumentReference _roosterDocument(String galleraId, String roosterId) {
    return _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('gallos')
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
    required String roosterName, // <-- NUEVO PARÁMETRO
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
          transaction.update(roosterDocRef, {'status': 'Descansando'});
        }
      });

      // --- ¡NUEVA LÓGICA! ---
      // Después de actualizar el combate, llamamos a la Cloud Function para
      // que actualice la transacción financiera correspondiente.
      final callable = _functions.httpsCallable('updateFightTransaction');
      await callable.call({
        'galleraId': galleraId,
        'roosterId': roosterId,
        'fightId': fightId,
        'netProfit': netProfit,
        'fightDate': date.toIso8601String(),
        'roosterName': roosterName,
        'opponent': opponent,
      });
    } on FirebaseFunctionsException catch (e) {
      print("Error en Cloud Function 'updateFightTransaction': ${e.message}");
      throw Exception(
          e.message ?? "Error al registrar la transacción del combate.");
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

      // --- ¡NUEVA LÓGICA! ---
      // Al borrar un combate, también borramos su transacción asociada
      // llamando a la misma función pero sin ganancia neta.
      final callable = _functions.httpsCallable('updateFightTransaction');
      await callable.call({
        'galleraId': galleraId,
        'roosterId': roosterId,
        'fightId': fightId,
        'netProfit':
            null, // Esto le indica a la función que debe borrar la transacción
        'fightDate': DateTime.now()
            .toIso8601String(), // La fecha es requerida pero no se usa para borrar
      });
    } on FirebaseFunctionsException catch (e) {
      print("Error en Cloud Function al borrar transacción: ${e.message}");
      // No relanzamos el error para no impedir el borrado local si la red falla
    } catch (e) {
      print("Error en FightService.deleteFight: $e");
      throw Exception("Ocurrió un error al borrar el evento.");
    }
  }
}
