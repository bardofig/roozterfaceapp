// lib/utils/error_handler.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ErrorHandler {
  /// Traduce excepciones comunes a mensajes amigables para el usuario.
  static String getUserFriendlyMessage(dynamic e) {
    // Primero, imprimimos el error real en la consola para depuración.
    print("Error original capturado: $e");

    String errorMessage =
        "Ocurrió un error inesperado. Por favor, inténtalo de nuevo.";

    if (e is FirebaseFunctionsException) {
      // Errores específicos de Cloud Functions
      switch (e.code) {
        case 'unauthenticated':
          errorMessage =
              "Tu sesión ha expirado. Por favor, inicia sesión de nuevo.";
          break;
        case 'permission-denied':
          errorMessage =
              "No tienes los permisos necesarios para realizar esta acción.";
          break;
        case 'invalid-argument':
          errorMessage =
              "Los datos proporcionados son incorrectos. Por favor, verifícalos.";
          break;
        case 'not-found':
          errorMessage =
              e.message ?? "El recurso solicitado no fue encontrado.";
          break;
        default:
          errorMessage = e.message ??
              "Ocurrió un error en el servidor. Inténtalo más tarde.";
      }
    } else if (e is FirebaseAuthException) {
      // Errores específicos de Firebase Authentication
      switch (e.code) {
        case 'invalid-email':
          errorMessage = "El formato del correo electrónico no es válido.";
          break;
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = "Correo electrónico o contraseña incorrectos.";
          break;
        case 'email-already-in-use':
          errorMessage =
              "Este correo electrónico ya está registrado. Por favor, inicia sesión.";
          break;
        case 'weak-password':
          errorMessage =
              "La contraseña es demasiado débil. Debe tener al menos 6 caracteres.";
          break;
        case 'operation-not-allowed':
          errorMessage =
              "La creación de cuentas no está habilitada en este momento.";
          break;
        default:
          errorMessage =
              "Ocurrió un error de autenticación. Inténtalo de nuevo.";
      }
    } else if (e is Exception) {
      // Errores genéricos que hemos lanzado nosotros mismos
      final message = e.toString().replaceFirst("Exception: ", "");
      if (!message.contains(RegExp(r'\[.*\]'))) {
        // Si no es un error técnico
        errorMessage = message;
      }
    }

    return errorMessage;
  }
}
