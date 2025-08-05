// lib/services/health_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roozterfaceapp/models/health_log_model.dart';

class HealthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Obtiene una referencia a la sub-sub-colección de registros de salud
  CollectionReference _healthLogsCollection(String roosterId) {
    if (currentUserId == null) throw Exception("Usuario no autenticado.");
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('gallos')
        .doc(roosterId)
        .collection('health_logs');
  }

  // Obtiene la lista de registros de salud para un gallo específico en tiempo real
  Stream<List<HealthLogModel>> getHealthLogsStream(String roosterId) {
    return _healthLogsCollection(roosterId)
        .orderBy(
          'date',
          descending: true,
        ) // Ordenamos por fecha, el más reciente primero
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HealthLogModel.fromFirestore(doc))
              .toList();
        });
  }

  // --- FUTUROS MÉTODOS ---
  // Dejamos el esqueleto preparado para el formulario de añadir registro.

  // Future<void> addHealthLog(String roosterId, Map<String, dynamic> logData) async {
  //   await _healthLogsCollection(roosterId).add(logData);
  // }
}
