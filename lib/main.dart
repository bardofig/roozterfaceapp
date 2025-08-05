import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

// Este será nuestro punto de partida. Más adelante, aquí decidiremos
// si el usuario ve la pantalla de login o la pantalla principal.
import 'package:roozterfaceapp/features/auth/presentation/screens/auth_gate.dart';

void main() async {
  // Asegura que todo esté inicializado antes de ejecutar la app
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Desactiva la cinta de "Debug" en la esquina de la app
      debugShowCheckedModeBanner: false,
      title: 'RoozterFaceApp',
      theme: ThemeData(
        // Definiremos un tema visual consistente más adelante
        primarySwatch: Colors.blue,
      ),
      // El punto de entrada visual de nuestra aplicación.
      // Crearemos este archivo en los siguientes pasos.
      home: const AuthGate(),
    );
  }
}
