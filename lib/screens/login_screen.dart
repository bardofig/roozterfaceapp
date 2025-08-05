// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roozterfaceapp/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final void Function()? onTap;
  const LoginScreen({super.key, required this.onTap});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para los campos de texto
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Instancia de nuestro servicio de autenticación
  final AuthService _authService = AuthService();

  // Método para mostrar un pop-up con un mensaje de error
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Error de Inicio de Sesión'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Método que se ejecuta al presionar el botón de Iniciar Sesión
  void signIn() async {
    // Mostrar un círculo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Llamar al método de inicio de sesión en nuestro servicio
      await _authService.signInWithEmailAndPassword(
        emailController.text,
        passwordController.text,
      );

      // Ocultar círculo de carga si todo sale bien
      // El AuthGate se encargará de la redirección
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Si hay un error, ocultar el círculo de carga y mostrar el mensaje
      Navigator.pop(context);
      showErrorMessage(e.toString().replaceAll("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          // SingleChildScrollView previene que el teclado tape los campos de texto
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  Icon(
                    Icons.shield_outlined,
                    size: 100,
                    color: Colors.grey[800],
                  ),
                  const SizedBox(height: 25),
                  Text(
                    'Bienvenido a RoozterFace',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.germaniaOne(
                      color: Colors.grey[800],
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 35),

                  // Campo de texto para el Email
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType
                        .emailAddress, // Teclado optimizado para email
                    decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      hintText: 'Email',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Campo de texto para la Contraseña
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    keyboardType: TextInputType
                        .visiblePassword, // Teclado para contraseñas
                    decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      hintText: 'Contraseña',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Botón de Iniciar Sesión
                  GestureDetector(
                    onTap: signIn, // Llama a nuestro método de lógica
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Enlace para ir a la pantalla de Registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes cuenta?',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                          'Regístrate ahora',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
