import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  // Le pasamos una función para poder cambiar a la pantalla de registro
  final void Function()? onTap;

  const LoginScreen({super.key, required this.onTap});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para los campos de texto
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Método para iniciar sesión (la lógica vendrá después)
  void signIn() {
    // Por ahora, solo mostraremos un mensaje en la consola
    print("Email: ${emailController.text}");
    print("Password: ${passwordController.text}");
    // Aquí es donde llamaremos a nuestro AuthService más adelante
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300], // Un fondo gris claro
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // Permite hacer scroll si el contenido no cabe
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),

                  // 1. Logo (usaremos un icono por ahora)
                  Icon(
                    Icons.lock_person, // Un icono representativo
                    size: 100,
                    color: Colors.grey[800],
                  ),

                  const SizedBox(height: 50),

                  // 2. Mensaje de bienvenida
                  Text(
                    'Bienvenido a RoozterFaceApp',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 3. Campo de texto para el Email
                  TextField(
                    controller: emailController,
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

                  // 4. Campo de texto para la Contraseña
                  TextField(
                    controller: passwordController,
                    obscureText: true, // Oculta el texto de la contraseña
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

                  // 5. Botón de Iniciar Sesión
                  GestureDetector(
                    onTap: signIn, // Llama a nuestro método signIn
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

                  // 6. Enlace para ir a la pantalla de Registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes cuenta?',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap:
                            widget.onTap, // Llama a la función que nos pasaron
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
