// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roozterfaceapp/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// --- MÉTODO REFACTORIZADO (PASO 1 DEL REGISTRO) ---
  /// Crea el usuario en Firebase Auth y un documento de perfil mínimo en Firestore.
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    UserCredential userCredential;
    try {
      // 1. Crear el usuario en Firebase Authentication
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Ocurrió un error de autenticación.");
    }

    User? newUser = userCredential.user;
    if (newUser == null) {
      throw Exception("No se pudo crear el usuario, intente de nuevo.");
    }

    // 2. Crear un documento de perfil MÍNIMO.
    // Usamos un mapa directamente para flexibilidad, ya que el UserModel requiere todos los campos.
    Map<String, dynamic> userProfileData = {
      'uid': newUser.uid,
      'email': email,
      'fullName': '', // Vacío para indicar perfil incompleto
      'mobilePhone': '',
      'street': '',
      'number': '',
      'betweenStreets': '',
      'postalCode': '',
      'neighborhood': '',
      'city': '',
      'country': '',
      'plan': 'iniciacion',
      'activeGalleraId': null,
      'galleraIds': [],
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection('users')
          .doc(newUser.uid)
          .set(userProfileData);
      return userCredential;
    } catch (e) {
      // Si la escritura en Firestore falla, revertimos la creación del usuario.
      await newUser.delete();
      throw Exception(
        "No se pudo guardar la información inicial del perfil. El registro se ha cancelado.",
      );
    }
  }

  /// --- ¡NUEVO MÉTODO! (PASO 2 DEL REGISTRO) ---
  /// Completa el perfil del usuario con datos adicionales y crea su primera gallera.
  Future<void> completeUserProfileAndCreateGallera({
    required String uid,
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
    WriteBatch batch = _firestore.batch();

    // 1. Preparar la creación de la gallera inicial
    DocumentReference galleraRef = _firestore.collection('galleras').doc();
    Map<String, dynamic> galleraData = {
      'name': 'Gallera de $fullName',
      'ownerId': uid,
      'members': {uid: 'propietario'},
      'createdAt': FieldValue.serverTimestamp(),
    };
    batch.set(galleraRef, galleraData);

    // 2. Preparar la actualización del perfil del usuario
    DocumentReference userRef = _firestore.collection('users').doc(uid);
    Map<String, dynamic> userProfileUpdates = {
      'fullName': fullName,
      'mobilePhone': mobilePhone,
      'street': street,
      'number': number,
      'betweenStreets': betweenStreets,
      'postalCode': postalCode,
      'neighborhood': neighborhood,
      'city': city,
      'country': country,
      'activeGalleraId': galleraRef.id, // Asignar la nueva gallera como activa
      'galleraIds': FieldValue.arrayUnion([galleraRef.id]), // Añadir a la lista
    };
    batch.update(userRef, userProfileUpdates);

    // 3. Ejecutar ambas operaciones de forma atómica
    await batch.commit();
  }

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
