// lib/services/health_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roozterfaceapp/models/health_log_model.dart';

class HealthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference _healthLogsCollection(String roosterId) {
    if (currentUserId == null) throw Exception("Usuario no autenticado.");
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('gallos')
        .doc(roosterId)
        .collection('health_logs');
  }

  Stream<List<HealthLogModel>> getHealthLogsStream(String roosterId) {
    return _healthLogsCollection(
      roosterId,
    ).orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => HealthLogModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> addHealthLog({
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
      await _healthLogsCollection(roosterId).add(logData);
    } catch (e) {
      throw Exception("Ocurrió un error al guardar el registro de salud.");
    }
  }

  // --- ¡NUEVO MÉTODO UPDATE! ---
  Future<void> updateHealthLog({
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
      await _healthLogsCollection(roosterId).doc(logId).update(logData);
    } catch (e) {
      throw Exception("Ocurrió un error al actualizar el registro de salud.");
    }
  }

  // --- MÉTODO DELETE (ya estaba, pero lo confirmamos) ---
  Future<void> deleteHealthLog({
    required String roosterId,
    required String logId,
  }) async {
    try {
      await _healthLogsCollection(roosterId).doc(logId).delete();
    } catch (e) {
      throw Exception("Ocurrió un error al borrar el registro de salud.");
    }
  }
}
