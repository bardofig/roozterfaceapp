import 'package:flutter/material.dart';

// 1. Importa los paquetes que acabamos de instalar
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Este archivo lo generó flutterfire_cli

void main() async {
  // 2. Convierte el main en una función asíncrona
  // 3. Asegúrate de que los bindings de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Inicializa Firebase usando las opciones para la plataforma actual
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 5. Ejecuta la aplicación
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoozterFaceApp',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Scaffold(
        // Pantalla de ejemplo temporal
        body: Center(child: Text('¡RoozterFaceApp Conectado a Firebase!')),
      ),
    );
  }
}
