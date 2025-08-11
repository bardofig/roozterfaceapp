// lib/services/health_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roozterfaceapp/models/health_log_model.dart';

class HealthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Apunta a la sub-sub-colección de salud, ahora desde /galleras
  CollectionReference _healthLogsCollection(
    String galleraId,
    String roosterId,
  ) {
    return _firestore
        .collection('galleras')
        .doc(galleraId)
        .collection('gallos')
        .doc(roosterId)
        .collection('health_logs');
  }

  // Obtiene la lista de registros de salud de una gallera y gallo específicos
  Stream<List<HealthLogModel>> getHealthLogsStream(
    String galleraId,
    String roosterId,
  ) {
    if (galleraId.isEmpty) return Stream.value([]);
    return _healthLogsCollection(
      galleraId,
      roosterId,
    ).orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => HealthLogModel.fromFirestore(doc))
          .toList();
    });
  }

  // Añade un registro de salud a una gallera y gallo específicos
  Future<void> addHealthLog({
    required String galleraId,
    required String roosterId,
    required DateTime date,
    required String logCategory,
    required String productName,
    String? illnessOrCondition,
    String? dosage,
    required String notes,
  }) async {
    try {
      Map<String, dynamic> logData = {
        'date': Timestamp.fromDate(date),
        'logCategory': logCategory,
        'productName': productName,
        'illnessOrCondition': illnessOrCondition,
        'dosage': dosage,
        'notes': notes,
      };
      await _healthLogsCollection(galleraId, roosterId).add(logData);
    } catch (e) {
      throw Exception("Ocurrió un error al guardar el registro de salud.");
    }
  }

  // Actualiza un registro de salud en una gallera y gallo específicos
  Future<void> updateHealthLog({
    required String galleraId,
    required String roosterId,
    required String logId,
    required DateTime date,
    required String logCategory,
    required String productName,
    String? illnessOrCondition,
    String? dosage,
    required String notes,
  }) async {
    try {
      Map<String, dynamic> logData = {
        'date': Timestamp.fromDate(date),
        'logCategory': logCategory,
        'productName': productName,
        'illnessOrCondition': illnessOrCondition,
        'dosage': dosage,
        'notes': notes,
      };
      await _healthLogsCollection(
        galleraId,
        roosterId,
      ).doc(logId).update(logData);
    } catch (e) {
      throw Exception("Ocurrió un error al actualizar el registro de salud.");
    }
  }

  // Borra un registro de salud de una gallera y gallo específicos
  Future<void> deleteHealthLog({
    required String galleraId,
    required String roosterId,
    required String logId,
  }) async {
    try {
      await _healthLogsCollection(galleraId, roosterId).doc(logId).delete();
    } catch (e) {
      throw Exception("Ocurrió un error al borrar el registro de salud.");
    }
  }
}
