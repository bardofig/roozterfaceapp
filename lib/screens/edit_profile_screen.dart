// lib/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:roozterfaceapp/models/user_model.dart';
import 'package:roozterfaceapp/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel userProfile;

  const EditProfileScreen({super.key, required this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Un controlador para cada campo editable
  late final TextEditingController _fullNameController;
  late final TextEditingController _mobilePhoneController;
  late final TextEditingController _streetController;
  late final TextEditingController _numberController;
  late final TextEditingController _betweenStreetsController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;

  final UserService _userService = UserService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Inicializamos los controladores con los datos actuales del usuario
    _fullNameController = TextEditingController(
      text: widget.userProfile.fullName,
    );
    _mobilePhoneController = TextEditingController(
      text: widget.userProfile.mobilePhone,
    );
    _streetController = TextEditingController(text: widget.userProfile.street);
    _numberController = TextEditingController(text: widget.userProfile.number);
    _betweenStreetsController = TextEditingController(
      text: widget.userProfile.betweenStreets,
    );
    _postalCodeController = TextEditingController(
      text: widget.userProfile.postalCode,
    );
    _neighborhoodController = TextEditingController(
      text: widget.userProfile.neighborhood,
    );
    _cityController = TextEditingController(text: widget.userProfile.city);
    _countryController = TextEditingController(
      text: widget.userProfile.country,
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobilePhoneController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _betweenStreetsController.dispose();
    _postalCodeController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // Validación simple
    if (_fullNameController.text.isEmpty || _cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre y la ciudad son obligatorios.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _userService.updateUserProfile(
        fullName: _fullNameController.text,
        mobilePhone: _mobilePhoneController.text,
        street: _streetController.text,
        number: _numberController.text,
        betweenStreets: _betweenStreetsController.text,
        postalCode: _postalCodeController.text,
        neighborhood: _neighborhoodController.text,
        city: _cityController.text,
        country: _countryController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado con éxito.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: type,
        textCapitalization: TextCapitalization.words,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(_fullNameController, 'Nombre Completo'),
            _buildTextField(
              _mobilePhoneController,
              'Teléfono Móvil',
              type: TextInputType.phone,
            ),
            const Divider(height: 32),
            _buildTextField(_streetController, 'Calle'),
            _buildTextField(_numberController, 'Número'),
            _buildTextField(_betweenStreetsController, 'Entre Calles'),
            _buildTextField(_neighborhoodController, 'Colonia'),
            _buildTextField(
              _postalCodeController,
              'Código Postal',
              type: TextInputType.number,
            ),
            _buildTextField(_cityController, 'Ciudad'),
            _buildTextField(_countryController, 'País'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar Cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
