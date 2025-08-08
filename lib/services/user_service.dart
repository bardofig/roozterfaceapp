// lib/services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Actualiza los datos del perfil del usuario en Firestore
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
      throw Exception("Usuario no autenticado.");
    }

    try {
      // Preparamos el mapa con los datos a actualizar
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

      // Apuntamos al documento del usuario y actualizamos los campos
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
