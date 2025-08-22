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

  /// Obtiene los perfiles de los miembros en un momento dado usando una Cloud Function.
  Future<List<Map<String, dynamic>>> getMemberDetails({
    required String galleraId,
  }) async {
    final callable = _functions.httpsCallable('getGalleraMemberDetails');
    try {
      final result = await callable.call<dynamic>({
        'galleraId': galleraId,
      });

      final List<dynamic> memberList = result.data as List<dynamic>;
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
      throw Exception(e.toString());
    }
  }

  /// --- MÉTODO CORREGIDO: COMBINA STREAM Y CLOUD FUNCTION ---
  /// Escucha cambios en la lista de miembros y, cuando los hay, llama a la Cloud
  /// Function para obtener los perfiles de forma segura.
  Stream<List<Map<String, dynamic>>> getMemberDetailsStream(
      {required String galleraId}) {
    if (galleraId.isEmpty) {
      return Stream.value([]);
    }

    // 1. Escuchamos cambios en el documento de la gallera.
    return _firestore
        .collection('galleras')
        .doc(galleraId)
        .snapshots()
        .asyncMap((galleraSnapshot) async {
      if (!galleraSnapshot.exists) {
        return [];
      }

      final galleraData = galleraSnapshot.data() as Map<String, dynamic>;
      final Map<String, dynamic> members = galleraData['members'] ?? {};

      if (members.keys.isEmpty) {
        return [];
      }

      // 2. En lugar de consultar 'users', llamamos a la Cloud Function segura.
      try {
        return await getMemberDetails(galleraId: galleraId);
      } catch (e) {
        // Si la función falla, propagamos el error al StreamBuilder.
        print("Error al llamar a getMemberDetails desde el stream: $e");
        throw e;
      }
    });
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
