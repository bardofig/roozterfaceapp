// lib/services/gallera_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GalleraService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<DocumentSnapshot> getGalleraStream(String galleraId) {
    if (galleraId.isEmpty) {
      return const Stream.empty();
    }
    return _firestore.collection('galleras').doc(galleraId).snapshots();
  }

  Stream<QuerySnapshot> getGallerasByIds(List<String> galleraIds) {
    if (galleraIds.isEmpty) {
      return const Stream.empty();
    }
    return _firestore
        .collection('galleras')
        .where(FieldPath.documentId, whereIn: galleraIds)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getMemberDetails({
    required String galleraId,
  }) async {
    final callable = _functions.httpsCallable('getGalleraMemberDetails');
    try {
      final result = await callable.call<dynamic>({
        'galleraId': galleraId,
      });

      // --- CORRECCIÓN DEFINITIVA: CONVERSIÓN MANUAL Y SEGURA ---
      final List<dynamic> memberList = result.data as List<dynamic>;
      // Creamos una nueva lista, convirtiendo cada mapa explícitamente.
      final List<Map<String, dynamic>> typedList =
          List<Map<String, dynamic>>.from(
        memberList.map((item) => Map<String, dynamic>.from(item as Map)),
      );
      return typedList;
    } on FirebaseFunctionsException catch (e) {
      print("Error en 'getGalleraMemberDetails': [${e.code}] ${e.message}");
      throw Exception(e.message ?? "Ocurrió un error en la nube.");
    } catch (e) {
      print("Error inesperado en getMemberDetails: $e");
      throw Exception(
          e.toString()); // Lanzamos el error de tipado para verlo claramente
    }
  }

  Future<void> updateGalleraName({
    required String galleraId,
    required String newName,
  }) async {
    if (galleraId.isEmpty || newName.isEmpty) {
      throw Exception("Datos inválidos.");
    }
    await _firestore.collection('galleras').doc(galleraId).update({
      'name': newName,
    });
  }

  Future<HttpsCallableResult> inviteMember({
    required String galleraId,
    required String invitedEmail,
    required String role,
  }) async {
    final callable = _functions.httpsCallable('inviteMemberToGallera');
    try {
      return await callable.call<dynamic>({
        'galleraId': galleraId,
        'invitedEmail': invitedEmail,
        'role': role,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<HttpsCallableResult> removeMember({
    required String galleraId,
    required String memberId,
  }) async {
    final callable = _functions.httpsCallable('removeMemberFromGallera');
    try {
      return await callable.call<dynamic>({
        'galleraId': galleraId,
        'memberId': memberId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message);
    }
  }
}
