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
    String? partidoId, // ✅ NUEVO
  }) async {
    try {
      final fight = FightModel(
        id: '',
        date: date,
        location: location,
        preparationNotes: preparationNotes,
        status: 'Programado',
        opponent: null,
        result: null,
        postFightNotes: null,
        survived: true,
        weaponType: null,
        fightDuration: null,
        injuriesSustained: null,
        netProfit: null,
        partidoId: partidoId, // ✅ NUEVO
      );
      await _fightsCollection(galleraId, roosterId).add(fight.toMap());
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

        DocumentSnapshot fightSnapshot = await transaction.get(fightDocRef);
        String? existingPartidoId;
        if (fightSnapshot.exists) {
          existingPartidoId = (fightSnapshot.data() as Map<String, dynamic>)['partidoId'];
        }

        final fight = FightModel(
          id: fightId,
          date: date,
          location: location,
          preparationNotes: preparationNotes,
          status: 'Completado',
          opponent: opponent,
          result: result,
          postFightNotes: postFightNotes,
          survived: survived,
          weaponType: weaponType,
          fightDuration: fightDuration,
          injuriesSustained: injuriesSustained,
          netProfit: netProfit,
          partidoId: existingPartidoId, // Mantenemos el partido original del combate
        );

        transaction.update(fightDocRef, fight.toMap());

        // --- ¡NUEVA LÓGICA DE ESTADÍSTICAS DE PARTIDO! ---
        if (fight.partidoId != null && fight.partidoId!.isNotEmpty) {
          DocumentReference partidoRef = _firestore.collection('partidos').doc(fight.partidoId);
          
          // Incrementamos contadores atómicamente
          int winInc = (result == 'Gana') ? 1 : 0;
          int lossInc = (result == 'Pierde') ? 1 : 0;
          int drawInc = (result == 'Empate' || result == 'Tablas') ? 1 : 0;
          int deadInc = survived ? 0 : 1;

          transaction.update(partidoRef, {
            'totalFights': FieldValue.increment(1),
            'wins': FieldValue.increment(winInc),
            'losses': FieldValue.increment(lossInc),
            'draws': FieldValue.increment(drawInc),
            'lostRoosters': FieldValue.increment(deadInc),
          });
        }

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
