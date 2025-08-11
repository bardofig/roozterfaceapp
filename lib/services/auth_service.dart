// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roozterfaceapp/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
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
    UserCredential userCredential;
    try {
      // 1. Crear el usuario en Firebase Authentication
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception("Error de autenticación: ${e.message}");
    }

    User? newUser = userCredential.user;
    if (newUser == null) {
      throw Exception("No se pudo crear el usuario, intente de nuevo.");
    }

    // Usamos una transacción de lote (WriteBatch) para asegurar que ambas
    // escrituras (gallera y perfil) se completen o ninguna lo haga.
    WriteBatch batch = _firestore.batch();

    try {
      // 2. Preparar la creación de una nueva gallera para este usuario.
      DocumentReference galleraRef = _firestore.collection('galleras').doc();
      Map<String, dynamic> galleraData = {
        'name': 'Gallera de $fullName',
        'ownerId': newUser.uid,
        'members': {newUser.uid: 'propietario'},
        'createdAt': FieldValue.serverTimestamp(),
      };
      batch.set(galleraRef, galleraData);

      // 3. Preparar la creación del perfil del usuario.
      DocumentReference userRef = _firestore
          .collection('users')
          .doc(newUser.uid);
      UserModel userModel = UserModel(
        uid: newUser.uid,
        email: email,
        fullName: fullName,
        mobilePhone: mobilePhone,
        street: street,
        number: number,
        betweenStreets: betweenStreets,
        postalCode: postalCode,
        neighborhood: neighborhood,
        city: city,
        country: country,
        activeGalleraId: galleraRef.id,
        galleraIds: [
          galleraRef.id,
        ], // Inicializamos la lista con su primera gallera
      );
      batch.set(userRef, userModel.toJson());

      // 4. Ejecutar todas las operaciones de escritura a la vez.
      await batch.commit();

      return userCredential;
    } catch (e) {
      // Si la escritura en Firestore falla, borramos el usuario de Auth para revertir.
      print(
        "Error al escribir en Firestore. Reversando creación de usuario de Auth... Error: $e",
      );
      await newUser.delete();
      throw Exception(
        "No se pudo guardar la información del perfil. El registro se ha cancelado.",
      );
    }
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
