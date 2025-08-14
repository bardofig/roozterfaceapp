// lib/services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Actualiza el ID de la gallera activa en el perfil del usuario.
  /// Esto controla qué gallera ve el usuario en la HomeScreen.
  Future<void> setActiveGallera(String galleraId) async {
    if (currentUserId == null) {
      throw Exception(
        "Usuario no autenticado. No se puede cambiar de gallera.",
      );
    }
    await _firestore.collection('users').doc(currentUserId).update({
      'activeGalleraId': galleraId,
    });
  }

  /// Actualiza los datos del perfil del usuario (nombre, dirección, etc.)
  Future<void> updateUserProfile({
    required String fullName,
    required String mobilePhone,
    required String street,
    required String number,
    required String betweenStreets,
    required String postalCode,
    required String neighborhood,
    required String city,
    required String country,
  }) async {
    if (currentUserId == null) {
      throw Exception(
        "Usuario no autenticado. No se pueden guardar los cambios del perfil.",
      );
    }

    try {
      Map<String, dynamic> updatedData = {
        'fullName': fullName,
        'mobilePhone': mobilePhone,
        'street': street,
        'number': number,
        'betweenStreets': betweenStreets,
        'postalCode': postalCode,
        'neighborhood': neighborhood,
        'city': city,
        'country': country,
      };

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update(updatedData);
    } catch (e) {
      print("Error al actualizar el perfil: $e");
      throw Exception("Ocurrió un error al guardar los cambios.");
    }
  }
}
