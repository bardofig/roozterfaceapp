// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roozterfaceapp/services/auth_service.dart';

// --- WIDGETS DE AYUDA (HELPERS) ---

// Helper para crear un título de sección estilizado
Widget _buildSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
      ),
    ),
  );
}

// Helper para crear un campo de texto (TextField) con nuestro estilo estándar
Widget _buildTextField({
  required TextEditingController controller,
  required String hintText,
  bool obscureText = false,
  TextInputType keyboardType = TextInputType.text,
  TextCapitalization textCapitalization = TextCapitalization.none,
}) {
  return TextField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    decoration: InputDecoration(
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      fillColor: Colors.grey.shade200,
      filled: true,
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[500]),
    ),
  );
}

// --- PANTALLA DE REGISTRO PRINCIPAL ---

class RegisterScreen extends StatefulWidget {
  final void Function()? onTap;
  const RegisterScreen({super.key, required this.onTap});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // === CONTROLADORES PARA TODOS LOS CAMPOS ===
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final fullNameController = TextEditingController();
  final mobilePhoneController = TextEditingController();
  final streetController = TextEditingController();
  final numberController = TextEditingController();
  final betweenStreetsController = TextEditingController();
  final postalCodeController = TextEditingController();
  final neighborhoodController = TextEditingController();
  final cityController = TextEditingController();
  final countryController = TextEditingController();

  // Instancia de nuestro servicio de autenticación
  final AuthService _authService = AuthService();

  // Método para mostrar un pop-up con un mensaje de error
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Error de Registro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // El método que se ejecuta al presionar el botón de registro
  void signUp() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    if (passwordController.text != confirmPasswordController.text) {
      Navigator.pop(context);
      showErrorMessage("Las contraseñas no coinciden. Por favor, verifícalas.");
      return;
    }

    if ([
      emailController,
      passwordController,
      fullNameController,
      mobilePhoneController,
      streetController,
      cityController,
      countryController,
    ].any((controller) => controller.text.isEmpty)) {
      Navigator.pop(context);
      showErrorMessage("Por favor, rellena todos los campos obligatorios.");
      return;
    }

    try {
      await _authService.signUpWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
        fullName: fullNameController.text,
        mobilePhone: mobilePhoneController.text,
        street: streetController.text,
        number: numberController.text,
        betweenStreets: betweenStreetsController.text,
        postalCode: postalCodeController.text,
        neighborhood: neighborhoodController.text,
        city: cityController.text,
        country: countryController.text,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 25),
                  Center(
                    child: Text(
                      'Crea tu cuenta en RoozterFace',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.germaniaOne(
                        color: Colors.grey[800],
                        fontSize: 32,
                      ),
                    ),
                  ),

                  _buildSectionTitle('Datos de la Cuenta'),
                  _buildTextField(
                    controller: emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: passwordController,
                    hintText: 'Contraseña',
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: confirmPasswordController,
                    hintText: 'Confirmar Contraseña',
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                  ),

                  _buildSectionTitle('Datos Personales'),
                  _buildTextField(
                    controller: fullNameController,
                    hintText: 'Nombre Completo',
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: mobilePhoneController,
                    hintText: 'Teléfono Móvil',
                    keyboardType: TextInputType.phone,
                  ),

                  _buildSectionTitle('Dirección'),
                  _buildTextField(
                    controller: streetController,
                    hintText: 'Calle',
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: numberController,
                    hintText: 'Número',
                    keyboardType: TextInputType.streetAddress,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: betweenStreetsController,
                    hintText: 'Entre Calles (Opcional)',
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: postalCodeController,
                    hintText: 'Código Postal',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: neighborhoodController,
                    hintText: 'Colonia o Barrio',
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: cityController,
                    hintText: 'Ciudad o Municipio',
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: countryController,
                    hintText: 'País',
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 25),

                  GestureDetector(
                    onTap: signUp,
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Crear mi Cuenta',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes una cuenta?',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                          'Inicia sesión ahora',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
