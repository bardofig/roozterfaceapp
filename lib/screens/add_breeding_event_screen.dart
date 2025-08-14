// lib/screens/add_breeding_event_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/services/breeding_service.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';

class AddBreedingEventScreen extends StatefulWidget {
  final String galleraId;

  const AddBreedingEventScreen({super.key, required this.galleraId});

  @override
  State<AddBreedingEventScreen> createState() => _AddBreedingEventScreenState();
}

class _AddBreedingEventScreenState extends State<AddBreedingEventScreen> {
  final _roosterService = RoosterService();
  final _breedingService = BreedingService();

  // Controladores de texto
  final _notesController = TextEditingController();
  final _externalFatherController = TextEditingController();
  final _externalMotherController = TextEditingController();

  // Estados
  DateTime? _selectedDate;
  RoosterModel? _selectedFather;
  RoosterModel? _selectedMother;
  bool _isLoading = false;
  bool _isExternalFather = false;
  bool _isExternalMother = false;

  late Future<List<RoosterModel>> _breedersFuture;

  @override
  void initState() {
    super.initState();
    _breedersFuture = _roosterService
        .getRoostersStream(widget.galleraId)
        .first
        .then((roosters) =>
            roosters.where((r) => r.status.toLowerCase() == 'activo').toList());
  }

  @override
  void dispose() {
    _notesController.dispose();
    _externalFatherController.dispose();
    _externalMotherController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    // Validación
    if ((_selectedFather == null && !_isExternalFather) ||
        (_externalFatherController.text.isEmpty && _isExternalFather)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, especifica un padre.')));
      return;
    }
    if ((_selectedMother == null && !_isExternalMother) ||
        (_externalMotherController.text.isEmpty && _isExternalMother)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, especifica una madre.')));
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecciona una fecha.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _breedingService.addBreedingEvent(
        galleraId: widget.galleraId,
        eventDate: _selectedDate!,
        notes: _notesController.text,
        // Pasa el padre interno o nulo
        father: _isExternalFather ? null : _selectedFather,
        // Pasa la madre interna o nula
        mother: _isExternalMother ? null : _selectedMother,
        // Pasa la descripción externa o nula
        externalFatherLineage:
            _isExternalFather ? _externalFatherController.text : null,
        externalMotherLineage:
            _isExternalMother ? _externalMotherController.text : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cruza registrada con éxito.')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Cruza')),
      body: FutureBuilder<List<RoosterModel>>(
        future: _breedersFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final breeders = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección del Padre
                Text("Semental (Padre)",
                    style: Theme.of(context).textTheme.titleMedium),
                SwitchListTile(
                  title: const Text('Padre Externo (No registrado)'),
                  value: _isExternalFather,
                  onChanged: (value) {
                    setState(() {
                      _isExternalFather = value;
                      if (value) _selectedFather = null;
                    });
                  },
                ),
                if (_isExternalFather)
                  TextField(
                    controller: _externalFatherController,
                    decoration: const InputDecoration(
                        labelText: 'Descripción del Padre Externo'),
                    textCapitalization: TextCapitalization.words,
                  )
                else
                  DropdownButtonFormField<RoosterModel>(
                    value: _selectedFather,
                    decoration: const InputDecoration(
                        labelText: 'Seleccionar Semental Registrado'),
                    isExpanded: true,
                    items: breeders
                        .map((r) => DropdownMenuItem<RoosterModel>(
                            value: r, child: Text('${r.name} (${r.plate})')))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedFather = v;
                      });
                    },
                  ),

                const Divider(height: 32),

                // Sección de la Madre
                Text("Gallina (Madre)",
                    style: Theme.of(context).textTheme.titleMedium),
                SwitchListTile(
                  title: const Text('Madre Externa (No registrada)'),
                  value: _isExternalMother,
                  onChanged: (value) {
                    setState(() {
                      _isExternalMother = value;
                      if (value) _selectedMother = null;
                    });
                  },
                ),
                if (_isExternalMother)
                  TextField(
                    controller: _externalMotherController,
                    decoration: const InputDecoration(
                        labelText: 'Descripción de la Madre Externa'),
                    textCapitalization: TextCapitalization.words,
                  )
                else
                  DropdownButtonFormField<RoosterModel>(
                    value: _selectedMother,
                    decoration: const InputDecoration(
                        labelText: 'Seleccionar Gallina Registrada'),
                    isExpanded: true,
                    items: breeders
                        .map((r) => DropdownMenuItem<RoosterModel>(
                            value: r, child: Text('${r.name} (${r.plate})')))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedMother = v;
                      });
                    },
                  ),

                const Divider(height: 32),

                // Sección de Fecha y Notas
                Row(
                  children: [
                    Expanded(
                        child: Text(_selectedDate == null
                            ? 'Fecha de la Cruza'
                            : 'Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}')),
                    TextButton(
                        onPressed: () => _selectDate(context),
                        child: const Text('Seleccionar')),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration:
                      const InputDecoration(labelText: 'Notas Adicionales'),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveEvent,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Guardar Cruza'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
