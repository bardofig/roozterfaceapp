// lib/services/invitation_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Escucha en tiempo real el documento de invitaciones del usuario actual.
  /// Emite el documento si existe, o null si no.
  Stream<DocumentSnapshot?> getInvitationsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      // Si no hay usuario, emite un stream vacío.
      return Stream.value(null);
    }
    return _firestore.collection('invitations').doc(user.uid).snapshots();
  }

  /// Llama a la Cloud Function para aceptar una invitación.
  Future<void> acceptInvitation(String galleraId) async {
    final callable = _functions.httpsCallable('acceptInvitation');
    try {
      await callable.call<dynamic>({'galleraId': galleraId});
    } on FirebaseFunctionsException catch (e) {
      print("Error al aceptar invitación: ${e.code} - ${e.message}");
      throw Exception(
          e.message ?? "Ocurrió un error al aceptar la invitación.");
    } catch (e) {
      print("Error inesperado al aceptar invitación: $e");
      throw Exception("No se pudo procesar la solicitud.");
    }
  }

  /// Llama a la Cloud Function para rechazar una invitación.
  Future<void> declineInvitation(String galleraId) async {
    final callable = _functions.httpsCallable('declineInvitation');
    try {
      await callable.call<dynamic>({'galleraId': galleraId});
    } on FirebaseFunctionsException catch (e) {
      print("Error al rechazar invitación: ${e.code} - ${e.message}");
      throw Exception(
          e.message ?? "Ocurrió un error al rechazar la invitación.");
    } catch (e) {
      print("Error inesperado al rechazar invitación: $e");
      throw Exception("No se pudo procesar la solicitud.");
    }
  }
}
