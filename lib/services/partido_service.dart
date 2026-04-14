// lib/services/partido_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:roozterfaceapp/models/partido_model.dart';

class PartidoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<PartidoModel?> getActivePartidoStream(String? partidoId) {
    if (partidoId == null || partidoId.isEmpty) {
      return Stream.value(null);
    }
    return _firestore.collection('partidos').doc(partidoId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PartidoModel.fromFirestore(doc);
    });
  }

  Stream<List<PartidoModel>> getAllPartidosStream() {
    return _firestore.collection('partidos').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PartidoModel.fromFirestore(doc)).toList();
    });
  }

  Future<String> createPartido({
    required String name,
    File? logoFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuario no autenticado");

    // 1. Crear el documento del partido
    final partidoDoc = _firestore.collection('partidos').doc();
    String? logoUrl;

    // 2. Subir logo si existe
    if (logoFile != null) {
      final ref = _storage.ref().child('partidos/${partidoDoc.id}/logo.jpg');
      await ref.putFile(logoFile);
      logoUrl = await ref.getDownloadURL();
    }

    final partido = PartidoModel(
      id: partidoDoc.id,
      name: name,
      logoUrl: logoUrl,
      ownerId: user.uid,
      members: {user.uid: 'propietario'},
      createdAt: DateTime.now(),
    );

    // 3. Guardar en Firestore y actualizar el perfil del usuario (Atomically)
    final batch = _firestore.batch();
    batch.set(partidoDoc, partido.toMap());
    batch.update(_firestore.collection('users').doc(user.uid), {
      'activePartidoId': partidoDoc.id,
    });

    await batch.commit();
    return partidoDoc.id;
  }

  Future<void> updatePartido({
    required String partidoId,
    String? name,
    File? logoFile,
  }) async {
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;

    if (logoFile != null) {
      final ref = _storage.ref().child('partidos/$partidoId/logo.jpg');
      await ref.putFile(logoFile);
      updates['logoUrl'] = await ref.getDownloadURL();
    }

    if (updates.isNotEmpty) {
      await _firestore.collection('partidos').doc(partidoId).update(updates);
    }
  }

  // Nota: Para invitaciones seguras se recomienda usar Cloud Functions.
  // Por ahora implementamos una búsqueda básica de miembro por email para este prototipo premium.
  Future<void> inviteMemberByEmail({
    required String partidoId,
    required String email,
  }) async {
    // Buscar el usuario por email
    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase().trim())
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception("No se encontró ningún usuario con ese correo electrónico.");
    }

    final invitedUid = userQuery.docs.first.id;

    // Actualizar el partido y el usuario
    final batch = _firestore.batch();
    batch.update(_firestore.collection('partidos').doc(partidoId), {
      'members.$invitedUid': 'socio',
    });
    batch.update(_firestore.collection('users').doc(invitedUid), {
      'activePartidoId': partidoId,
    });

    await batch.commit();
  }

  Future<void> removeMember({
    required String partidoId,
    required String memberId,
  }) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('partidos').doc(partidoId), {
      'members.$memberId': FieldValue.delete(),
    });
    batch.update(_firestore.collection('users').doc(memberId), {
      'activePartidoId': null,
    });

    await batch.commit();
  }
}
