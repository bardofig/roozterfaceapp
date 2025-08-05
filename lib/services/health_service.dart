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
    return _healthLogsCollection(
      roosterId,
    ).orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => HealthLogModel.fromFirestore(doc))
          .toList();
    });
  }

  // --- ¡MÉTODO AÑADIDO Y FUNCIONAL! ---
  // Añade un nuevo registro de salud a la base de datos
  Future<void> addHealthLog({
    required String roosterId,
    required DateTime date,
    required String logType,
    required String description,
    required String notes,
  }) async {
    if (currentUserId == null) {
      throw Exception("Usuario no autenticado.");
    }
    try {
      // Preparamos los datos en un mapa para Firestore
      Map<String, dynamic> logData = {
        'date': Timestamp.fromDate(date),
        'logType': logType,
        'description': description,
        'notes': notes,
      };

      // Añadimos el nuevo documento a la sub-sub-colección
      await _healthLogsCollection(roosterId).add(logData);
    } catch (e) {
      print("Error al guardar el registro de salud: $e");
      throw Exception("Ocurrió un error al guardar el registro de salud.");
    }
  }
}
