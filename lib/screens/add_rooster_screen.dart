// lib/screens/add_rooster_screen.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/data/breed_data.dart';
import 'package:roozterfaceapp/data/options_data.dart';
import 'package:roozterfaceapp/models/area_model.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/services/area_service.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';

enum Sex { macho, hembra }

class AddRoosterScreen extends StatefulWidget {
  final RoosterModel? roosterToEdit;
  final String currentUserPlan;
  final String activeGalleraId;
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
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _fatherLineageController = TextEditingController();
  final _motherLineageController = TextEditingController();
  final _weightController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _buyerNameController = TextEditingController();
  final _saleNotesController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedStatus;
  late List<String> _statuses;
  File? _selectedImage;
  bool _isSaving = false;
  String? _selectedFatherId;
  String? _selectedMotherId;
  String? _selectedBreedLine;
  String? _selectedColor;
  String? _selectedCombType;
  String? _selectedLegColor;
  AreaModel? _selectedArea;
  BreedProfile? _selectedBreedProfile;
  DateTime? _saleDate;
  bool _showInShowcase = false;
  bool _isExternalFather = false;
  bool _isExternalMother = false;
  Set<Sex> _selectedSex = {Sex.macho};

  final RoosterService _roosterService = RoosterService();
  final AreaService _areaService = AreaService();
  late Future<List<dynamic>> _initialDataFuture;

  @override
  void initState() {
    super.initState();
    _initialDataFuture = Future.wait([
      _roosterService.getRoostersStream(widget.activeGalleraId).first,
      _areaService.getAreasStream(widget.activeGalleraId).first,
    ]);
    _statuses = [
      'Activo',
      'En Venta',
      'Vendido',
      'Descansando',
      'Herido',
      'Perdido en Combate'
    ];
    if (widget.roosterToEdit != null) {
      _loadRoosterData(widget.roosterToEdit!);
    } else {
      _initializeNewRooster();
    }
  }

  void _loadRoosterData(RoosterModel rooster) {
    if (rooster.status == 'Vendido' && !_statuses.contains('Vendido'))
      _statuses.add('Vendido');
    _nameController.text = rooster.name;
    _plateController.text = rooster.plate;
    _selectedDate = rooster.birthDate.toDate();
    _selectedStatus = rooster.status;
    _weightController.text = rooster.weight?.toString() ?? '';
    _selectedBreedLine = rooster.breedLine;
    _selectedColor = rooster.color;
    _selectedCombType = rooster.combType;
    _selectedLegColor = rooster.legColor;
    _salePriceController.text = rooster.salePrice?.toStringAsFixed(2) ?? '';
    _buyerNameController.text = rooster.buyerName ?? '';
    _saleNotesController.text = rooster.saleNotes ?? '';
    _saleDate = rooster.saleDate?.toDate();
    _showInShowcase = rooster.showInShowcase ?? false;
    _selectedSex = rooster.sex == 'hembra' ? {Sex.hembra} : {Sex.macho};
    if (rooster.fatherId != null && rooster.fatherId!.isNotEmpty) {
      _isExternalFather = false;
      _selectedFatherId = rooster.fatherId;
    } else if (rooster.fatherLineageText != null &&
        rooster.fatherLineageText!.isNotEmpty) {
      _isExternalFather = true;
      _fatherLineageController.text = rooster.fatherLineageText!;
    }
    if (rooster.motherId != null && rooster.motherId!.isNotEmpty) {
      _isExternalMother = false;
      _selectedMotherId = rooster.motherId;
    } else if (rooster.motherLineageText != null &&
        rooster.motherLineageText!.isNotEmpty) {
      _isExternalMother = true;
      _motherLineageController.text = rooster.motherLineageText!;
    }
    _initialDataFuture.then((data) {
      if (mounted && rooster.areaId != null) {
        final areas = data[1] as List<AreaModel>;
        setState(() {
          try {
            _selectedArea = areas.firstWhere((a) => a.id == rooster.areaId);
          } catch (e) {}
        });
      }
    });
    _updateBreedProfile();
  }

  void _initializeNewRooster() {
    _selectedStatus = 'Activo';
    if (widget.initialFatherId != null) {
      _isExternalFather = false;
      _selectedFatherId = widget.initialFatherId;
    } else if (widget.initialFatherLineage != null) {
      _isExternalFather = true;
      _fatherLineageController.text = widget.initialFatherLineage!;
    }
    if (widget.initialMotherId != null) {
      _isExternalMother = false;
      _selectedMotherId = widget.initialMotherId;
    } else if (widget.initialMotherLineage != null) {
      _isExternalMother = true;
      _motherLineageController.text = widget.initialMotherLineage!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _fatherLineageController.dispose();
    _motherLineageController.dispose();
    _weightController.dispose();
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
    final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime.now());
    if (picked != null) {
      setState(() => isSaleDate ? _saleDate = picked : _selectedDate = picked);
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
              child: Wrap(children: [
            ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería de Fotos'),
                onTap: () {
                  _getImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                }),
            ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Cámara'),
                onTap: () {
                  _getImage(ImageSource.camera);
                  Navigator.of(context).pop();
                }),
          ]));
        });
  }

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveRooster(List<RoosterModel> allRoosters) async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      if (_selectedDate == null)
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

    RoosterModel? fatherData;
    try {
      if (_selectedFatherId != null)
        fatherData = allRoosters.firstWhere((r) => r.id == _selectedFatherId);
    } catch (e) {
      fatherData = null;
    }
    RoosterModel? motherData;
    try {
      if (_selectedMotherId != null)
        motherData = allRoosters.firstWhere((r) => r.id == _selectedMotherId);
    } catch (e) {
      motherData = null;
    }

    final salePrice = _salePriceController.text.isNotEmpty
        ? double.tryParse(_salePriceController.text)
        : null;
    final weight = _weightController.text.isNotEmpty
        ? double.tryParse(_weightController.text)
        : null;
    final fatherIdToSave = _isExternalFather ? null : _selectedFatherId;
    final fatherNameToSave = _isExternalFather ? null : fatherData?.name;
    final fatherLineageToSave =
        _isExternalFather ? _fatherLineageController.text.trim() : "";
    final motherIdToSave = _isExternalMother ? null : _selectedMotherId;
    final motherNameToSave = _isExternalMother ? null : motherData?.name;
    final motherLineageToSave =
        _isExternalMother ? _motherLineageController.text.trim() : "";

    try {
      if (widget.roosterToEdit != null) {
        await _roosterService.updateRooster(
          galleraId: widget.activeGalleraId,
          roosterId: widget.roosterToEdit!.id,
          name: _nameController.text,
          plate: _plateController.text,
          status: _selectedStatus!,
          birthDate: _selectedDate!,
          sex: _selectedSex.first.name,
          newImageFile: _selectedImage,
          existingImageUrl: widget.roosterToEdit!.imageUrl,
          fatherId: fatherIdToSave,
          fatherName: fatherNameToSave,
          fatherLineageText: fatherLineageToSave,
          motherId: motherIdToSave,
          motherName: motherNameToSave,
          motherLineageText: motherLineageToSave,
          breedLine: _selectedBreedLine,
          color: _selectedColor,
          combType: _selectedCombType,
          legColor: _selectedLegColor,
          salePrice: salePrice,
          saleDate: _saleDate,
          buyerName: _buyerNameController.text,
          saleNotes: _saleNotesController.text,
          showInShowcase: _showInShowcase,
          weight: weight,
          areaId: _selectedArea?.id,
          areaName: _selectedArea?.name,
        );
      } else {
        await _roosterService.addNewRooster(
          galleraId: widget.activeGalleraId,
          name: _nameController.text,
          plate: _plateController.text,
          status: _selectedStatus!,
          birthDate: _selectedDate!,
          sex: _selectedSex.first.name,
          imageFile: _selectedImage!,
          fatherId: fatherIdToSave,
          fatherName: fatherNameToSave,
          motherId: motherIdToSave,
          motherName: motherNameToSave,
          fatherLineageText: fatherLineageToSave,
          motherLineageText: motherLineageToSave,
          breedLine: _selectedBreedLine,
          color: _selectedColor,
          combType: _selectedCombType,
          legColor: _selectedLegColor,
          salePrice: salePrice,
          showInShowcase: _showInShowcase,
          weight: weight,
          areaId: _selectedArea?.id,
          areaName: _selectedArea?.name,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Ejemplar guardado con éxito!')));
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
    final isMaestroOrHigher = widget.currentUserPlan != 'iniciacion';
    final isEliteUser = widget.currentUserPlan == 'elite';
    bool showSalePriceField =
        _selectedStatus == 'En Venta' || _selectedStatus == 'Vendido';
    bool showSoldFields = _selectedStatus == 'Vendido';
    bool showShowcaseSwitch = _selectedStatus == 'En Venta' && isEliteUser;

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.roosterToEdit != null
              ? 'Editar Ejemplar'
              : 'Añadir Nuevo Ejemplar')),
      body: FutureBuilder<List<dynamic>>(
        future: _initialDataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
                child: Text("Error al cargar datos: ${snapshot.error}"));

          final allRoosters = snapshot.data![0] as List<RoosterModel>;
          final areas = snapshot.data![1] as List<AreaModel>;

          final possibleSires =
              allRoosters.where((r) => r.sex == 'macho').toList();
          final sireDropdownItems = possibleSires
              .map((rooster) => DropdownMenuItem<String>(
                  value: rooster.id,
                  child: Text("${rooster.name} (${rooster.plate})")))
              .toList();
          if (widget.roosterToEdit != null &&
              _selectedFatherId != null &&
              !possibleSires.any((p) => p.id == _selectedFatherId)) {
            try {
              final father =
                  allRoosters.firstWhere((r) => r.id == _selectedFatherId);
              sireDropdownItems.add(DropdownMenuItem<String>(
                  value: father.id,
                  child: Text("${father.name} (${father.plate})")));
            } catch (e) {}
          }
          final validFatherId = _selectedFatherId != null &&
                  allRoosters.any((p) => p.id == _selectedFatherId)
              ? _selectedFatherId
              : null;

          final possibleDams =
              allRoosters.where((r) => r.sex == 'hembra').toList();
          final damDropdownItems = possibleDams
              .map((rooster) => DropdownMenuItem<String>(
                  value: rooster.id,
                  child: Text("${rooster.name} (${rooster.plate})")))
              .toList();
          if (widget.roosterToEdit != null &&
              _selectedMotherId != null &&
              !possibleDams.any((p) => p.id == _selectedMotherId)) {
            try {
              final mother =
                  allRoosters.firstWhere((r) => r.id == _selectedMotherId);
              damDropdownItems.add(DropdownMenuItem<String>(
                  value: mother.id,
                  child: Text("${mother.name} (${mother.plate})")));
            } catch (e) {}
          }
          final validMotherId = _selectedMotherId != null &&
                  allRoosters.any((p) => p.id == _selectedMotherId)
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
                      child: Stack(alignment: Alignment.bottomRight, children: [
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
                                  widget.roosterToEdit!.imageUrl.isNotEmpty))
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
                        onPressed: _pickImage),
                  ])),
                  const SizedBox(height: 24),
                  Center(
                    child: SegmentedButton<Sex>(
                      segments: const <ButtonSegment<Sex>>[
                        ButtonSegment<Sex>(
                            value: Sex.macho,
                            label: Text('Gallo'),
                            icon: Icon(Icons.male)),
                        ButtonSegment<Sex>(
                            value: Sex.hembra,
                            label: Text('Gallina'),
                            icon: Icon(Icons.female)),
                      ],
                      selected: _selectedSex,
                      onSelectionChanged: (Set<Sex> newSelection) {
                        setState(() {
                          if (newSelection.isNotEmpty)
                            _selectedSex = newSelection;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text("Datos del Ejemplar",
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nombre *'),
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
                          .map((s) => DropdownMenuItem<String>(
                              value: s, child: Text(s)))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedStatus = newValue;
                          if (newValue == 'Vendido' && _saleDate == null)
                            _saleDate = DateTime.now();
                        });
                      }),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                          labelText: 'Peso (ej: 2.5)', suffixText: 'kg'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<AreaModel>(
                      value: _selectedArea,
                      decoration: const InputDecoration(
                          labelText: 'Ubicación en la Gallera'),
                      isExpanded: true,
                      items: areas
                          .map((area) => DropdownMenuItem<AreaModel>(
                              value: area, child: Text(area.name)))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedArea = value);
                      }),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                      value: _selectedBreedLine,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Línea / Casta'),
                      items: breedProfiles
                          .map((p) => DropdownMenuItem<String>(
                              value: p.name, child: Text(p.name)))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedBreedLine = newValue;
                        });
                        _updateBreedProfile();
                      }),
                  if (_selectedBreedProfile != null)
                    _buildBreedInfoCard(_selectedBreedProfile!),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                      value: _selectedColor,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Color de Plumaje'),
                      items: plumageColorOptions
                          .map((c) => DropdownMenuItem<String>(
                              value: c, child: Text(c)))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedColor = newValue;
                        });
                      }),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                      value: _selectedCombType,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Tipo de Cresta'),
                      items: combTypeOptions
                          .map((t) => DropdownMenuItem<String>(
                              value: t, child: Text(t)))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedCombType = newValue;
                        });
                      }),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                      value: _selectedLegColor,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Color de Patas'),
                      items: legColorOptions
                          .map((c) => DropdownMenuItem<String>(
                              value: c, child: Text(c)))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedLegColor = newValue;
                        });
                      }),
                  if (isMaestroOrHigher && showSalePriceField)
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 32),
                          Text("Detalles de Venta",
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          TextFormField(
                              controller: _salePriceController,
                              decoration: const InputDecoration(
                                  labelText: 'Precio (\$)', prefixText: '\$'),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true)),
                        ]),
                  if (showShowcaseSwitch)
                    SwitchListTile(
                        title: const Text('Mostrar en Escaparate'),
                        value: _showInShowcase,
                        onChanged: (v) => setState(() => _showInShowcase = v)),
                  if (isMaestroOrHigher && showSoldFields)
                    Column(children: [
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _buyerNameController,
                          decoration:
                              const InputDecoration(labelText: 'Comprador'),
                          textCapitalization: TextCapitalization.words),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                            child: Text(
                                'Fecha Venta: ${DateFormat('dd/MM/yyyy').format(_saleDate!)}')),
                        TextButton(
                            onPressed: () =>
                                _selectDate(context, isSaleDate: true),
                            child: const Text('Cambiar'))
                      ]),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _saleNotesController,
                          decoration: const InputDecoration(
                              labelText: 'Notas de Venta'),
                          maxLines: 2,
                          textCapitalization: TextCapitalization.sentences),
                    ]),
                  if (isMaestroOrHigher)
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 32),
                          Text("Linaje",
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          SwitchListTile(
                              title: const Text('Padre Externo'),
                              value: _isExternalFather,
                              onChanged: (v) {
                                setState(() {
                                  _isExternalFather = v;
                                  if (v)
                                    _selectedFatherId = null;
                                  else
                                    _fatherLineageController.clear();
                                });
                              }),
                          if (_isExternalFather)
                            TextFormField(
                                controller: _fatherLineageController,
                                decoration: const InputDecoration(
                                    labelText: 'Descripción Padre Externo*'),
                                validator: (v) =>
                                    _isExternalFather && v!.isEmpty
                                        ? 'Obligatorio'
                                        : null,
                                textCapitalization: TextCapitalization.words)
                          else
                            DropdownButtonFormField<String>(
                                value: validFatherId,
                                decoration: const InputDecoration(
                                    labelText: 'Padre Registrado'),
                                items: sireDropdownItems,
                                onChanged: (v) {
                                  setState(() => _selectedFatherId = v);
                                },
                                isExpanded: true),
                          const SizedBox(height: 24),
                          SwitchListTile(
                              title: const Text('Madre Externa'),
                              value: _isExternalMother,
                              onChanged: (v) {
                                setState(() {
                                  _isExternalMother = v;
                                  if (v)
                                    _selectedMotherId = null;
                                  else
                                    _motherLineageController.clear();
                                });
                              }),
                          if (_isExternalMother)
                            TextFormField(
                                controller: _motherLineageController,
                                decoration: const InputDecoration(
                                    labelText: 'Descripción Madre Externa*'),
                                validator: (v) =>
                                    _isExternalMother && v!.isEmpty
                                        ? 'Obligatorio'
                                        : null,
                                textCapitalization: TextCapitalization.words)
                          else
                            DropdownButtonFormField<String>(
                                value: validMotherId,
                                decoration: const InputDecoration(
                                    labelText: 'Madre Registrada'),
                                items: damDropdownItems,
                                onChanged: (v) {
                                  setState(() => _selectedMotherId = v);
                                },
                                isExpanded: true),
                        ]),
                  const SizedBox(height: 32),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () => _saveRooster(allRoosters),
                          style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: _isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(widget.roosterToEdit != null
                                  ? 'Guardar Cambios'
                                  : 'Añadir Ejemplar'))),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildInfoRow(
            Icons.sports_kabaddi, "Estilo de Pelea:", profile.fightingStyle),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.biotech, "Notas de Cría:", profile.breedingNotes),
      ]),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String content) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
      const SizedBox(width: 8),
      Expanded(
          child: Text.rich(TextSpan(
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        children: [
          TextSpan(
              text: '$title ',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          TextSpan(text: content, style: const TextStyle(fontSize: 12)),
        ],
      ))),
    ]);
  }
}
