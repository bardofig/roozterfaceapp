import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Instancia de Firebase Auth para interactuar con el servicio
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Más adelante aquí pondremos los métodos:
  // 1. Stream para escuchar el estado de autenticación
  // 2. Método para iniciar sesión con email y contraseña
  // 3. Método para registrar un nuevo usuario
  // 4. Método para cerrar sesión
}
