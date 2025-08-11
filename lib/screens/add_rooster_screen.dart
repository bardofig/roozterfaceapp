// lib/screens/add_rooster_screen.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/data/breed_data.dart';
import 'package:roozterfaceapp/data/options_data.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';

class AddRoosterScreen extends StatefulWidget {
  final RoosterModel? roosterToEdit;
  final String currentUserPlan;
  final String activeGalleraId;

  const AddRoosterScreen({
    super.key,
    this.roosterToEdit,
    required this.currentUserPlan,
    required this.activeGalleraId,
  });

  @override
  State<AddRoosterScreen> createState() => _AddRoosterScreenState();
}

class _AddRoosterScreenState extends State<AddRoosterScreen> {
  final _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  static const _formPageStorageKey = PageStorageKey('addRoosterForm');

  // Controladores
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _fatherLineageController = TextEditingController();
  final _motherLineageController = TextEditingController();

  // Variables de Estado
  DateTime? _selectedDate;
  String? _selectedStatus;
  final List<String> _statuses = [
    'Activo',
    'En Venta',
    'Descansando',
    'Herido',
    'Perdido en Combate',
  ];
  File? _selectedImage;
  final RoosterService _roosterService = RoosterService();
  bool _isSaving = false;
  String? _selectedFatherId;
  String? _selectedMotherId;
  String? _selectedBreedLine;
  String? _selectedColor;
  String? _selectedCombType;
  String? _selectedLegColor;
  BreedProfile? _selectedBreedProfile;

  @override
  void initState() {
    super.initState();
    if (widget.roosterToEdit != null) {
      final rooster = widget.roosterToEdit!;
      _nameController.text = rooster.name;
      _plateController.text = rooster.plate;
      _selectedDate = rooster.birthDate.toDate();
      _selectedStatus = rooster.status;
      _fatherLineageController.text = rooster.fatherLineageText ?? '';
      _motherLineageController.text = rooster.motherLineageText ?? '';
      _selectedFatherId = rooster.fatherId;
      _selectedMotherId = rooster.motherId;
      _selectedBreedLine = rooster.breedLine;
      _selectedColor = rooster.color;
      _selectedCombType = rooster.combType;
      _selectedLegColor = rooster.legColor;
      _updateBreedProfile();
    } else {
      _selectedStatus = 'Activo';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _plateController.dispose();
    _fatherLineageController.dispose();
    _motherLineageController.dispose();
    super.dispose();
  }

  void _updateBreedProfile() {
    if (_selectedBreedLine != null) {
      try {
        setState(() {
          _selectedBreedProfile = breedProfiles.firstWhere(
            (p) => p.name == _selectedBreedLine,
          );
        });
      } catch (e) {
        setState(() {
          _selectedBreedProfile = null;
        });
      }
    } else {
      setState(() {
        _selectedBreedProfile = null;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería de Fotos'),
                onTap: () {
                  _getImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Cámara'),
                onTap: () {
                  _getImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveRooster(List<RoosterModel> allRoosters) async {
    if (_nameController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El Nombre y la Fecha son obligatorios.')),
      );
      return;
    }
    if (widget.roosterToEdit == null && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una imagen.')),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });

    final fatherData = _selectedFatherId != null
        ? allRoosters.firstWhere(
            (r) => r.id == _selectedFatherId,
            orElse: () => RoosterModel(
              id: '',
              name: '',
              plate: '',
              status: '',
              birthDate: Timestamp.now(),
            ),
          )
        : null;
    final motherData = _selectedMotherId != null
        ? allRoosters.firstWhere(
            (r) => r.id == _selectedMotherId,
            orElse: () => RoosterModel(
              id: '',
              name: '',
              plate: '',
              status: '',
              birthDate: Timestamp.now(),
            ),
          )
        : null;

    try {
      if (widget.roosterToEdit != null) {
        await _roosterService.updateRooster(
          galleraId: widget.activeGalleraId,
          roosterId: widget.roosterToEdit!.id,
          name: _nameController.text,
          plate: _plateController.text,
          status: _selectedStatus!,
          birthDate: _selectedDate!,
          newImageFile: _selectedImage,
          existingImageUrl: widget.roosterToEdit!.imageUrl,
          fatherId: _selectedFatherId,
          fatherName: fatherData?.name,
          motherId: _selectedMotherId,
          motherName: motherData?.name,
          fatherLineageText: _fatherLineageController.text,
          motherLineageText: _motherLineageController.text,
          breedLine: _selectedBreedLine,
          color: _selectedColor,
          combType: _selectedCombType,
          legColor: _selectedLegColor,
        );
      } else {
        await _roosterService.addNewRooster(
          galleraId: widget.activeGalleraId,
          name: _nameController.text,
          plate: _plateController.text,
          status: _selectedStatus!,
          birthDate: _selectedDate!,
          imageFile: _selectedImage!,
          fatherId: _selectedFatherId,
          fatherName: fatherData?.name,
          motherId: _selectedMotherId,
          motherName: motherData?.name,
          fatherLineageText: _fatherLineageController.text,
          motherLineageText: _motherLineageController.text,
          breedLine: _selectedBreedLine,
          color: _selectedColor,
          combType: _selectedCombType,
          legColor: _selectedLegColor,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Gallo guardado con éxito!')),
        );
        Navigator.of(context).pop();
        if (widget.roosterToEdit != null) {
          Navigator.of(context).pop();
        }
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

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.roosterToEdit != null;
    final bool isMaestroOrHigher = widget.currentUserPlan != 'iniciacion';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Gallo' : 'Añadir Nuevo Gallo'),
      ),
      body: StreamBuilder<List<RoosterModel>>(
        stream: _roosterService.getRoostersStream(widget.activeGalleraId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final allRoosters = snapshot.data ?? [];

          final List<String> breedingStatuses = ['activo', 'descansando'];
          final possibleParents = allRoosters.where((r) {
            final isNotSelf = isEditing
                ? r.id != widget.roosterToEdit!.id
                : true;
            final isBreedable = breedingStatuses.contains(
              r.status.toLowerCase(),
            );
            return isNotSelf && isBreedable;
          }).toList();

          final dropdownItems = possibleParents
              .map(
                (rooster) => DropdownMenuItem<String>(
                  value: rooster.id,
                  child: Text("${rooster.name} (${rooster.plate})"),
                ),
              )
              .toList();

          final validFatherId =
              _selectedFatherId != null &&
                  possibleParents.any((p) => p.id == _selectedFatherId)
              ? _selectedFatherId
              : null;
          final validMotherId =
              _selectedMotherId != null &&
                  possibleParents.any((p) => p.id == _selectedMotherId)
              ? _selectedMotherId
              : null;

          return SingleChildScrollView(
            key: _formPageStorageKey,
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (isEditing &&
                                            widget
                                                .roosterToEdit!
                                                .imageUrl
                                                .isNotEmpty
                                        ? NetworkImage(
                                            widget.roosterToEdit!.imageUrl,
                                          )
                                        : null)
                                    as ImageProvider?,
                          child:
                              (_selectedImage == null &&
                                  !(isEditing &&
                                      widget
                                          .roosterToEdit!
                                          .imageUrl
                                          .isNotEmpty))
                              ? Icon(
                                  Icons.camera_alt,
                                  size: 50,
                                  color: Colors.grey.shade700,
                                )
                              : null,
                        ),
                        IconButton(
                          icon: const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.black,
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          onPressed: _pickImage,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    "Datos del Ejemplar",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Gallo *',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _plateController,
                    decoration: const InputDecoration(
                      labelText: 'Placa / Anillo',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'Fecha de Nacimiento *'
                              : 'Nacimiento: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _selectDate(context),
                        child: const Text('Seleccionar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: _statuses.map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedStatus = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedBreedLine,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Línea / Casta',
                    ),
                    items: breedProfiles
                        .map(
                          (BreedProfile profile) => DropdownMenuItem<String>(
                            value: profile.name,
                            child: Text(profile.name),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedBreedLine = newValue;
                      });
                      _updateBreedProfile();
                    },
                  ),
                  if (_selectedBreedProfile != null)
                    _buildBreedInfoCard(_selectedBreedProfile!),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedColor,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Color de Plumaje',
                    ),
                    items: plumageColorOptions
                        .map(
                          (String color) => DropdownMenuItem<String>(
                            value: color,
                            child: Text(color),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedColor = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCombType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Cresta',
                    ),
                    items: combTypeOptions
                        .map(
                          (String type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCombType = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedLegColor,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Color de Patas',
                    ),
                    items: legColorOptions
                        .map(
                          (String color) => DropdownMenuItem<String>(
                            value: color,
                            child: Text(color),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedLegColor = newValue;
                      });
                    },
                  ),

                  if (isMaestroOrHigher)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 32),
                        Text(
                          "Linaje (Plan Maestro Criador)",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: validFatherId,
                          decoration: const InputDecoration(
                            labelText: 'Padre (Semental Registrado)',
                          ),
                          items: dropdownItems,
                          onChanged: (newValue) {
                            setState(() {
                              _selectedFatherId = newValue;
                              if (newValue != null) {
                                _fatherLineageController.clear();
                              }
                            });
                          },
                          isExpanded: true,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _fatherLineageController,
                          decoration: InputDecoration(
                            labelText: 'Línea Paterna (si no está registrado)',
                            enabled: _selectedFatherId == null,
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          value: validMotherId,
                          decoration: const InputDecoration(
                            labelText: 'Madre (Gallina Registrada)',
                          ),
                          items: dropdownItems,
                          onChanged: (newValue) {
                            setState(() {
                              _selectedMotherId = newValue;
                              if (newValue != null) {
                                _motherLineageController.clear();
                              }
                            });
                          },
                          isExpanded: true,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _motherLineageController,
                          decoration: InputDecoration(
                            labelText: 'Línea Materna (si no está registrada)',
                            enabled: _selectedMotherId == null,
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ],
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () => _saveRooster(allRoosters),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : Text(
                              isEditing ? 'Guardar Cambios' : 'Guardar Gallo',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBreedInfoCard(BreedProfile profile) {
    return Container(
      margin: const EdgeInsets.only(top: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            Icons.sports_kabaddi,
            "Estilo de Pelea:",
            profile.fightingStyle,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.biotech, "Notas de Cría:", profile.breedingNotes),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                TextSpan(text: content, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
