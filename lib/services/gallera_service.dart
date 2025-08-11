// lib/services/gallera_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:roozterfaceapp/models/user_model.dart';

class GalleraService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  // Obtiene los datos de una gallera específica en tiempo real
  Stream<DocumentSnapshot> getGalleraStream(String galleraId) {
    if (galleraId.isEmpty) {
      return const Stream.empty();
    }
    return _firestore.collection('galleras').doc(galleraId).snapshots();
  }

  // Obtiene una lista de documentos de galleras a partir de una lista de IDs
  Stream<QuerySnapshot> getGallerasByIds(List<String> galleraIds) {
    if (galleraIds.isEmpty) {
      return const Stream.empty();
    }
    // Usamos 'whereIn' para obtener todos los documentos cuya ID esté en la lista
    return _firestore
        .collection('galleras')
        .where(FieldPath.documentId, whereIn: galleraIds)
        .snapshots();
  }

  // Obtiene los perfiles de usuario de los miembros de una gallera
  Stream<List<UserModel>> getMembersProfilesStream(List<String> memberIds) {
    if (memberIds.isEmpty) {
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: memberIds)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();
        });
  }

  // Actualiza el nombre de una gallera
  Future<void> updateGalleraName({
    required String galleraId,
    required String newName,
  }) async {
    if (galleraId.isEmpty || newName.isEmpty) {
      throw Exception(
        "El ID de la gallera y el nuevo nombre no pueden estar vacíos.",
      );
    }
    await _firestore.collection('galleras').doc(galleraId).update({
      'name': newName,
    });
  }

  // Llama a la Cloud Function para invitar a un nuevo miembro
  Future<HttpsCallableResult> inviteMember({
    required String galleraId,
    required String invitedEmail,
    required String role,
  }) async {
    final callable = _functions.httpsCallable('inviteMemberToGallera');
    try {
      return await callable.call(<String, dynamic>{
        'galleraId': galleraId,
        'invitedEmail': invitedEmail,
        'role': role,
      });
    } on FirebaseFunctionsException catch (e) {
      // Hacemos que el mensaje de error sea más legible para la UI
      print("Error de Cloud Function: ${e.code} - ${e.message}");
      throw Exception(e.message);
    }
  }
}
