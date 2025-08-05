// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:roozterfaceapp/screens/splash_screen.dart'; // Apunta a la pantalla de bienvenida
import 'firebase_options.dart'; // Archivo de configuración de Firebase

void main() async {
  // Asegura que todos los bindings de Flutter estén listos antes de ejecutar la app
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase usando las opciones de configuración para la plataforma actual
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Ejecuta el widget raíz de la aplicación
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Desactiva la cinta de "Debug" en la esquina de la app
      debugShowCheckedModeBanner: false,
      // El título de la aplicación, usado por el sistema operativo
      title: 'RoozterFace',
      // Define el tema visual básico de la aplicación
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // La primera pantalla que se mostrará al abrir la aplicación
      home: const SplashScreen(),
    );
  }
}
