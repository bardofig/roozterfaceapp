// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roozterfaceapp/models/user_model.dart'; // Importamos nuestro modelo de datos de usuario

class AuthService {
  // Instancia privada de Firebase Authentication para interactuar con el servicio
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Instancia privada de Cloud Firestore para interactuar con la base de datos
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- MÉTODO DE REGISTRO ---
  // Se encarga de crear el usuario en Auth y guardar su perfil en Firestore
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
    try {
      // Paso 1: Crear el usuario en el servicio de Firebase Authentication
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Paso 2: Crear un objeto de nuestro modelo UserModel con todos los datos del perfil
      UserModel newUser = UserModel(
        uid: userCredential
            .user!
            .uid, // Obtenemos el UID único del usuario recién creado
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
        // Por defecto, todos los nuevos usuarios se asignan al plan 'iniciacion'
      );

      // Paso 3: Guardar el perfil del nuevo usuario en nuestra base de datos Firestore.
      // Creamos un documento en la colección 'users' y usamos el UID como su ID,
      // creando un vínculo perfecto entre el usuario de Auth y su perfil en Firestore.
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(newUser.toJson());

      // Si todo sale bien, devolvemos las credenciales del usuario
      return userCredential;
    }
    // Capturamos errores específicos de Firebase Auth para poder mostrarlos en la UI
    on FirebaseAuthException catch (e) {
      // Relanzamos la excepción para que el widget que llamó a este método la capture
      throw Exception(e.message);
    }
  }

  // --- MÉTODO DE INICIO DE SESIÓN ---
  // Se encarga de validar las credenciales de un usuario existente
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Usamos el método proporcionado por Firebase para iniciar sesión
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Si las credenciales son correctas, devolvemos el objeto UserCredential
      return userCredential;
    }
    // Capturamos los posibles errores para manejarlos en la UI
    on FirebaseAuthException catch (e) {
      // Relanzamos la excepción con un mensaje claro que la UI pueda interpretar
      throw Exception(e.message);
    }
  }

  // --- MÉTODO DE CIERRE DE SESIÓN ---
  // Se encarga de eliminar la sesión activa del usuario
  Future<void> signOut() async {
    // Simplemente llamamos al método signOut de Firebase Auth.
    // No necesitamos manejar errores aquí, ya que es una operación muy segura.
    await _auth.signOut();
  }
}
