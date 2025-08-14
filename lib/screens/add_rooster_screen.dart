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

  // Parámetros opcionales para pre-rellenar el linaje
  final String? initialFatherId;
  final String? initialMotherId;
  final String? initialFatherLineage;
  final String? initialMotherLineage;

  const AddRoosterScreen({
    super.key,
    this.roosterToEdit,
    required this.currentUserPlan,
    required this.activeGalleraId,
    this.initialFatherId,
    this.initialMotherId,
    this.initialFatherLineage,
    this.initialMotherLineage,
  });

  @override
  State<AddRoosterScreen> createState() => _AddRoosterScreenState();
}

class _AddRoosterScreenState extends State<AddRoosterScreen> {
  final _formKey = GlobalKey<FormState>();
  // Controladores Generales
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _fatherLineageController = TextEditingController();
  final _motherLineageController = TextEditingController();
  // Controladores de Venta
  final _salePriceController = TextEditingController();
  final _buyerNameController = TextEditingController();
  final _saleNotesController = TextEditingController();

  // Estados Generales
  DateTime? _selectedDate;
  String? _selectedStatus;
  late List<String> _statuses;
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
  // Estados de Venta
  DateTime? _saleDate;
  bool _showInShowcase = false;

  Future<List<RoosterModel>>? _parentsFuture;

  @override
  void initState() {
    super.initState();
    _parentsFuture =
        _roosterService.getRoostersStream(widget.activeGalleraId).first;
    _statuses = [
      'Activo',
      'En Venta',
      'Descansando',
      'Herido',
      'Perdido en Combate'
    ];

    if (widget.roosterToEdit != null) {
      // Modo Edición
      final rooster = widget.roosterToEdit!;
      if (rooster.status == 'Vendido' && !_statuses.contains('Vendido')) {
        _statuses.add('Vendido');
      }
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
      _salePriceController.text = rooster.salePrice?.toStringAsFixed(2) ?? '';
      _buyerNameController.text = rooster.buyerName ?? '';
      _saleNotesController.text = rooster.saleNotes ?? '';
      _saleDate = rooster.saleDate?.toDate();
      _showInShowcase = rooster.showInShowcase ?? false;
      _updateBreedProfile();
    } else {
      // Modo Creación
      _selectedStatus = 'Activo';
      if (widget.initialFatherId != null)
        _selectedFatherId = widget.initialFatherId;
      if (widget.initialFatherLineage != null)
        _fatherLineageController.text = widget.initialFatherLineage!;
      if (widget.initialMotherId != null)
        _selectedMotherId = widget.initialMotherId;
      if (widget.initialMotherLineage != null)
        _motherLineageController.text = widget.initialMotherLineage!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _fatherLineageController.dispose();
    _motherLineageController.dispose();
    _salePriceController.dispose();
    _buyerNameController.dispose();
    _saleNotesController.dispose();
    super.dispose();
  }

  void _updateBreedProfile() {
    if (_selectedBreedLine != null) {
      try {
        setState(() => _selectedBreedProfile =
            breedProfiles.firstWhere((p) => p.name == _selectedBreedLine));
      } catch (e) {
        setState(() => _selectedBreedProfile = null);
      }
    } else {
      setState(() => _selectedBreedProfile = null);
    }
  }

  Future<void> _selectDate(BuildContext context,
      {bool isSaleDate = false}) async {
    final initial = isSaleDate
        ? (_saleDate ?? DateTime.now())
        : (_selectedDate ?? DateTime.now());
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isSaleDate) {
          _saleDate = picked;
        } else {
          _selectedDate = picked;
        }
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
    final XFile? pickedFile =
        await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveRooster(List<RoosterModel> allRoosters) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('La fecha de nacimiento es obligatoria.')));
      return;
    }
    if (widget.roosterToEdit == null && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecciona una imagen.')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final fatherData = _selectedFatherId != null
        ? allRoosters.firstWhere((r) => r.id == _selectedFatherId,
            orElse: () => RoosterModel(
                id: '',
                name: '',
                plate: '',
                status: '',
                birthDate: Timestamp.now()))
        : null;
    final motherData = _selectedMotherId != null
        ? allRoosters.firstWhere((r) => r.id == _selectedMotherId,
            orElse: () => RoosterModel(
                id: '',
                name: '',
                plate: '',
                status: '',
                birthDate: Timestamp.now()))
        : null;
    final double? salePrice = double.tryParse(_salePriceController.text);

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
          salePrice: salePrice,
          saleDate: _saleDate,
          buyerName: _buyerNameController.text,
          saleNotes: _saleNotesController.text,
          showInShowcase: _showInShowcase,
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
          salePrice: salePrice,
          showInShowcase: _showInShowcase,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Gallo guardado con éxito!')));
        Navigator.of(context).pop();
        if (widget.roosterToEdit != null) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: ${e.toString()}')));
    } finally {
      if (mounted)
        setState(() {
          _isSaving = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMaestroOrHigher = widget.currentUserPlan != 'iniciacion';
    final bool isEliteUser = widget.currentUserPlan == 'elite';

    bool showSalePriceField =
        _selectedStatus == 'En Venta' || _selectedStatus == 'Vendido';
    bool showSoldFields = _selectedStatus == 'Vendido';
    bool showShowcaseSwitch = _selectedStatus == 'En Venta' && isEliteUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roosterToEdit != null
            ? 'Editar Gallo'
            : 'Añadir Nuevo Gallo'),
      ),
      body: FutureBuilder<List<RoosterModel>>(
        future: _parentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text("Error al cargar datos: ${snapshot.error}"));
          }

          final allRoosters = snapshot.data ?? [];
          final possibleParents = allRoosters
              .where((r) =>
                  (widget.roosterToEdit == null ||
                      r.id != widget.roosterToEdit!.id) &&
                  ['activo', 'descansando'].contains(r.status.toLowerCase()))
              .toList();
          final dropdownItems = possibleParents
              .map((rooster) => DropdownMenuItem<String>(
                  value: rooster.id,
                  child: Text("${rooster.name} (${rooster.plate})")))
              .toList();
          final validFatherId = _selectedFatherId != null &&
                  possibleParents.any((p) => p.id == _selectedFatherId)
              ? _selectedFatherId
              : null;
          final validMotherId = _selectedMotherId != null &&
                  possibleParents.any((p) => p.id == _selectedMotherId)
              ? _selectedMotherId
              : null;

          return SingleChildScrollView(
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
                              : (widget.roosterToEdit != null &&
                                      widget.roosterToEdit!.imageUrl.isNotEmpty
                                  ? NetworkImage(widget.roosterToEdit!.imageUrl)
                                  : null) as ImageProvider?,
                          child: (_selectedImage == null &&
                                  !(widget.roosterToEdit != null &&
                                      widget
                                          .roosterToEdit!.imageUrl.isNotEmpty))
                              ? Icon(Icons.camera_alt,
                                  size: 50, color: Colors.grey.shade700)
                              : null,
                        ),
                        IconButton(
                          icon: const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.black,
                              child: Icon(Icons.edit,
                                  color: Colors.white, size: 20)),
                          onPressed: _pickImage,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text("Datos del Ejemplar",
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          labelText: 'Nombre del Gallo *'),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v!.isEmpty ? 'El nombre es obligatorio' : null),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _plateController,
                      decoration:
                          const InputDecoration(labelText: 'Placa / Anillo')),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                        child: Text(
                            _selectedDate == null
                                ? 'Fecha de Nacimiento *'
                                : 'Nacimiento: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                            style: const TextStyle(fontSize: 16))),
                    TextButton(
                        onPressed: () => _selectDate(context),
                        child: const Text('Seleccionar'))
                  ]),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: _statuses
                        .map((s) =>
                            DropdownMenuItem<String>(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedStatus = newValue;
                        if (newValue == 'Vendido' && _saleDate == null)
                          _saleDate = DateTime.now();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedBreedLine,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Línea / Casta'),
                    items: breedProfiles
                        .map((BreedProfile profile) => DropdownMenuItem<String>(
                            value: profile.name, child: Text(profile.name)))
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
                    decoration:
                        const InputDecoration(labelText: 'Color de Plumaje'),
                    items: plumageColorOptions
                        .map((String color) => DropdownMenuItem<String>(
                            value: color, child: Text(color)))
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
                    decoration:
                        const InputDecoration(labelText: 'Tipo de Cresta'),
                    items: combTypeOptions
                        .map((String type) => DropdownMenuItem<String>(
                            value: type, child: Text(type)))
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
                    decoration:
                        const InputDecoration(labelText: 'Color de Patas'),
                    items: legColorOptions
                        .map((String color) => DropdownMenuItem<String>(
                            value: color, child: Text(color)))
                        .toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedLegColor = newValue;
                      });
                    },
                  ),

                  // --- SECCIÓN DE VENTAS DINÁMICA ---
                  if (isMaestroOrHigher && showSalePriceField)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 32),
                        Text("Detalles de Venta (Plan Maestro)",
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: _salePriceController,
                            decoration: const InputDecoration(
                                labelText: 'Precio de Venta (\$)',
                                prefixText: '\$ '),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true)),
                      ],
                    ),

                  if (showShowcaseSwitch)
                    SwitchListTile(
                      title:
                          const Text('Mostrar en Escaparate Público (Élite)'),
                      value: _showInShowcase,
                      onChanged: (value) =>
                          setState(() => _showInShowcase = value),
                    ),

                  if (isMaestroOrHigher && showSoldFields)
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: _buyerNameController,
                            decoration: const InputDecoration(
                                labelText: 'Nombre del Comprador'),
                            textCapitalization: TextCapitalization.words),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                              child: Text(
                                  'Fecha de Venta: ${DateFormat('dd/MM/yyyy').format(_saleDate!)}')),
                          TextButton(
                              onPressed: () =>
                                  _selectDate(context, isSaleDate: true),
                              child: const Text('Cambiar'))
                        ]),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: _saleNotesController,
                            decoration: const InputDecoration(
                                labelText: 'Notas de la Venta'),
                            maxLines: 2,
                            textCapitalization: TextCapitalization.sentences),
                      ],
                    ),

                  if (isMaestroOrHigher)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 32),
                        Text("Linaje (Plan Maestro Criador)",
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: validFatherId,
                          decoration: const InputDecoration(
                              labelText: 'Padre (Semental Registrado)'),
                          items: dropdownItems,
                          onChanged: (newValue) {
                            setState(() {
                              _selectedFatherId = newValue;
                              if (newValue != null)
                                _fatherLineageController.clear();
                            });
                          },
                          isExpanded: true,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: _fatherLineageController,
                            decoration: InputDecoration(
                                labelText:
                                    'Línea Paterna (si no está registrado)',
                                enabled: _selectedFatherId == null),
                            textCapitalization: TextCapitalization.words),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          value: validMotherId,
                          decoration: const InputDecoration(
                              labelText: 'Madre (Gallina Registrada)'),
                          items: dropdownItems,
                          onChanged: (newValue) {
                            setState(() {
                              _selectedMotherId = newValue;
                              if (newValue != null)
                                _motherLineageController.clear();
                            });
                          },
                          isExpanded: true,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: _motherLineageController,
                            decoration: InputDecoration(
                                labelText:
                                    'Línea Materna (si no está registrada)',
                                enabled: _selectedMotherId == null),
                            textCapitalization: TextCapitalization.words),
                      ],
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isSaving ? null : () => _saveRooster(allRoosters),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : Text(widget.roosterToEdit != null
                              ? 'Guardar Cambios'
                              : 'Guardar Gallo'),
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
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
              Icons.sports_kabaddi, "Estilo de Pelea:", profile.fightingStyle),
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
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              children: [
                TextSpan(
                    text: '$title ',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                TextSpan(text: content, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
