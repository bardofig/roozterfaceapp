// lib/screens/complete_profile_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roozterfaceapp/services/auth_service.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  // Controladores para todos los campos del perfil
  final fullNameController = TextEditingController();
  final mobilePhoneController = TextEditingController();
  final streetController = TextEditingController();
  final numberController = TextEditingController();
  final betweenStreetsController = TextEditingController();
  final postalCodeController = TextEditingController();
  final neighborhoodController = TextEditingController();
  final cityController = TextEditingController();
  final countryController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isSaving = false;

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Error al guardar'),
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

  Future<void> _saveProfileAndContinue() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Caso improbable, pero es una buena práctica de seguridad
      _authService.signOut();
      return;
    }

    // Validación de campos
    if ([
      fullNameController,
      mobilePhoneController,
      streetController,
      cityController,
      countryController
    ].any((controller) => controller.text.trim().isEmpty)) {
      showErrorMessage(
          "Por favor, completa todos los campos para continuar. Son necesarios para crear tu primera gallera.");
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _authService.completeUserProfileAndCreateGallera(
        uid: currentUser.uid,
        fullName: fullNameController.text.trim(),
        mobilePhone: mobilePhoneController.text.trim(),
        street: streetController.text.trim(),
        number: numberController.text.trim(),
        betweenStreets: betweenStreetsController.text.trim(),
        postalCode: postalCodeController.text.trim(),
        neighborhood: neighborhoodController.text.trim(),
        city: cityController.text.trim(),
        country: countryController.text.trim(),
      );
      // No necesitamos navegar desde aquí, el AuthGate detectará el perfil
      // completo en la siguiente reconstrucción y nos llevará a HomeScreen.
    } catch (e) {
      if (mounted) {
        showErrorMessage(e.toString().replaceAll("Exception: ", ""));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.words,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: hintText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Completa tu Perfil"),
        automaticallyImplyLeading: false, // Oculta el botón de retroceso
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _authService.signOut(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '¡Bienvenido!',
              style: GoogleFonts.germaniaOne(
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Solo un paso más. Completa tu información para crear tu primera gallera y empezar a gestionar tus ejemplares.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: fullNameController,
              hintText: 'Nombre Completo *',
            ),
            _buildTextField(
              controller: mobilePhoneController,
              hintText: 'Teléfono Móvil *',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: streetController,
              hintText: 'Calle *',
            ),
            _buildTextField(
              controller: numberController,
              hintText: 'Número Exterior/Interior',
            ),
            _buildTextField(
              controller: betweenStreetsController,
              hintText: 'Entre Calles (Opcional)',
            ),
            _buildTextField(
              controller: neighborhoodController,
              hintText: 'Colonia o Barrio',
            ),
            _buildTextField(
              controller: postalCodeController,
              hintText: 'Código Postal',
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              controller: cityController,
              hintText: 'Ciudad o Municipio *',
            ),
            _buildTextField(
              controller: countryController,
              hintText: 'País *',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfileAndContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Guardar y Continuar',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
