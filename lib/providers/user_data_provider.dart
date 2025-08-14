// lib/providers/user_data_provider.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:roozterfaceapp/models/user_model.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';
import 'package:roozterfaceapp/services/user_service.dart';

class UserDataProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RoosterService _roosterService = RoosterService();
  final UserService _userService = UserService();

  UserModel? _userProfile;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;
  StreamSubscription<User?>? _authSubscription;
  bool _isLoading = true;
  bool _isCorrecting = false; // Bandera para evitar bucles de corrección

  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  UserDataProvider() {
    // Escuchamos los cambios en el estado de autenticación (login/logout)
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Se activa cuando un usuario inicia o cierra sesión.
  Future<void> _onAuthStateChanged(User? user) async {
    // Si un usuario inicia sesión, empezamos a escuchar su perfil.
    if (user != null) {
      _isLoading = true;
      notifyListeners();
      await _profileSubscription?.cancel();
      _profileSubscription =
          _roosterService.getUserProfileStream().listen(_onProfileUpdated);
    }
    // Si el usuario cierra sesión, limpiamos todo.
    else {
      _isLoading = false;
      _userProfile = null;
      await _profileSubscription?.cancel();
      notifyListeners();
    }
  }

  /// Se activa cada vez que el documento del perfil del usuario en Firestore cambia.
  Future<void> _onProfileUpdated(DocumentSnapshot snapshot) async {
    // Si ya estamos en medio de una corrección, ignoramos este evento para evitar bucles.
    if (_isCorrecting) return;

    if (snapshot.exists) {
      final userProfile = UserModel.fromFirestore(snapshot);

      // --- VERIFICACIÓN DE COHERENCIA ---
      // ¿La gallera activa del usuario todavía está en su lista de galleras permitidas?
      final bool isActiveGalleraValid = userProfile.activeGalleraId != null &&
          userProfile.galleraIds.contains(userProfile.activeGalleraId);

      if (!isActiveGalleraValid && userProfile.activeGalleraId != null) {
        // ¡INCOHERENCIA DETECTADA! El usuario fue eliminado de su gallera activa.
        print(
            "Incoherencia detectada: La gallera activa '${userProfile.activeGalleraId}' ya no está en la lista de galleras permitidas.");

        _isCorrecting =
            true; // Levantamos la bandera para bloquear nuevas acciones

        // Acción correctiva: cambiar a la primera gallera disponible, o a ninguna si no hay.
        final String newActiveGalleraId = userProfile.galleraIds.isNotEmpty
            ? userProfile.galleraIds.first
            : '';

        try {
          await _userService.setActiveGallera(newActiveGalleraId);
          print(
              "Acción correctiva: Se cambió la gallera activa a: '$newActiveGalleraId'");
          // No hacemos nada más aquí. El Stream de Firebase nos notificará de este cambio,
          // y este método (_onProfileUpdated) se volverá a ejecutar. En la próxima ejecución,
          // la verificación de coherencia pasará y el estado se actualizará correctamente.
        } catch (e) {
          print("Error al ejecutar la acción correctiva de gallera: $e");
        } finally {
          // Bajamos la bandera después de la operación.
          _isCorrecting = false;
        }
      } else {
        // Si todo es coherente, actualizamos el estado de la app.
        _userProfile = userProfile;
        _isLoading = false;
        notifyListeners();
      }
    } else {
      // El perfil del usuario no existe en la base de datos.
      _userProfile = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
