// lib/services/area_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roozterfaceapp/models/area_model.dart';

class AreaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Apunta a la subcolección de áreas dentro de una gallera específica
  CollectionReference _areasCollection(String galleraId) {
    return _firestore.collection('galleras').doc(galleraId).collection('areas');
  }

  /// Obtiene un stream de todas las áreas de una gallera, ordenadas por nombre.
  Stream<List<AreaModel>> getAreasStream(String galleraId) {
    if (galleraId.isEmpty) {
      return Stream.value([]);
    }
    return _areasCollection(galleraId).orderBy('name').snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => AreaModel.fromFirestore(doc)).toList());
  }

  /// Añade una nueva área a la gallera.
  Future<void> addArea({
    required String galleraId,
    required String name,
    required String category,
    String? description,
  }) async {
    if (name.trim().isEmpty) {
      throw Exception('El nombre del área no puede estar vacío.');
    }
    final newArea = {
      'name': name,
      'category': category,
      'description': description,
    };
    await _areasCollection(galleraId).add(newArea);
  }

  /// Actualiza un área existente.
  Future<void> updateArea({
    required String galleraId,
    required String areaId,
    required String name,
    required String category,
    String? description,
  }) async {
    if (name.trim().isEmpty) {
      throw Exception('El nombre del área no puede estar vacío.');
    }
    final updatedArea = {
      'name': name,
      'category': category,
      'description': description,
    };
    await _areasCollection(galleraId).doc(areaId).update(updatedArea);
  }

  /// Elimina un área.
  /// ADVERTENCIA: Esto no reasigna automáticamente los gallos que estaban en esta área.
  /// Esa es una lógica más compleja que podríamos implementar en el futuro.
  Future<void> deleteArea({
    required String galleraId,
    required String areaId,
  }) async {
    await _areasCollection(galleraId).doc(areaId).delete();
  }
}
