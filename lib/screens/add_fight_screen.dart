// lib/screens/add_fight_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/data/options_data.dart';
import 'package:roozterfaceapp/models/fight_model.dart';
import 'package:roozterfaceapp/services/fight_service.dart';

class AddFightScreen extends StatefulWidget {
  final String roosterId;
  final FightModel? fightToEdit;

  const AddFightScreen({super.key, required this.roosterId, this.fightToEdit});

  @override
  State<AddFightScreen> createState() => _AddFightScreenState();
}

class _AddFightScreenState extends State<AddFightScreen> {
  // Controladores
  final _locationController = TextEditingController();
  final _opponentController = TextEditingController();
  final _prepNotesController = TextEditingController();
  final _postNotesController = TextEditingController();
  final _injuriesController = TextEditingController();

  // Variables de estado
  DateTime? _selectedDate;
  String? _selectedResult;
  final List<String> _results = ['Victoria', 'Derrota', 'Tabla'];
  bool _survived = true;
  String? _selectedWeaponType;
  String? _selectedDuration;

  final FightService _fightService = FightService();
  bool _isSaving = false;
  bool get _isEditing => widget.fightToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final fight = widget.fightToEdit!;
      _locationController.text = fight.location;
      _opponentController.text = fight.opponent ?? '';
      _prepNotesController.text = fight.preparationNotes ?? '';
      _postNotesController.text = fight.postFightNotes ?? '';
      _selectedDate = fight.date;
      _survived = fight.survived ?? true;
      _injuriesController.text = fight.injuriesSustained ?? '';

      // --- ¡LÓGICA DE VALIDACIÓN CORREGIDA! ---
      // Validamos cada valor antes de asignarlo.

      // Validar Resultado
      if (fight.result != null && _results.contains(fight.result)) {
        _selectedResult = fight.result;
      }

      // Validar Arma
      if (fight.weaponType != null &&
          weaponTypeOptions.contains(fight.weaponType)) {
        _selectedWeaponType = fight.weaponType;
      }

      // Validar Duración
      if (fight.fightDuration != null &&
          fightDurationOptions.contains(fight.fightDuration)) {
        _selectedDuration = fight.fightDuration;
      }
    } else {
      // Valores por defecto al crear
      _selectedResult = 'Victoria';
      _selectedWeaponType = weaponTypeOptions.isNotEmpty
          ? weaponTypeOptions[0]
          : null;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _opponentController.dispose();
    _prepNotesController.dispose();
    _postNotesController.dispose();
    _injuriesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveFight() async {
    if (_selectedDate == null || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La Fecha y el Lugar son obligatorios.')),
      );
      return;
    }
    if (_isEditing &&
        (_opponentController.text.isEmpty || _selectedResult == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El Oponente y el Resultado son obligatorios para completar un evento.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        await _fightService.updateFight(
          roosterId: widget.roosterId,
          fightId: widget.fightToEdit!.id,
          date: _selectedDate!,
          location: _locationController.text,
          preparationNotes: _prepNotesController.text,
          opponent: _opponentController.text,
          result: _selectedResult,
          postFightNotes: _postNotesController.text,
          survived: _survived,
          weaponType: _selectedWeaponType,
          fightDuration: _selectedDuration,
          injuriesSustained: _injuriesController.text,
        );
      } else {
        await _fightService.addFight(
          roosterId: widget.roosterId,
          date: _selectedDate!,
          location: _locationController.text,
          preparationNotes: _prepNotesController.text,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento de combate guardado.')),
        );
        Navigator.of(context).pop();
        if (_isEditing) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Actualizar Resultado' : 'Programar Combate'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Fecha del Evento *'
                        : 'Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
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
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Lugar / Derby *'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _prepNotesController,
              decoration: const InputDecoration(
                labelText: 'Notas de Preparación',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),

            if (_isEditing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 32),
                  Text(
                    "Resultado del Combate",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _opponentController,
                    decoration: const InputDecoration(
                      labelText: 'Oponente (Placa o Descripción) *',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedResult,
                    decoration: const InputDecoration(labelText: 'Resultado *'),
                    items: _results
                        .map(
                          (String result) => DropdownMenuItem<String>(
                            value: result,
                            child: Text(result),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedResult = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedWeaponType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Arma Utilizada',
                    ),
                    items: weaponTypeOptions
                        .map(
                          (String weapon) => DropdownMenuItem<String>(
                            value: weapon,
                            child: Text(weapon),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedWeaponType = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedDuration,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Duración de la Pelea',
                    ),
                    items: fightDurationOptions
                        .map(
                          (String duration) => DropdownMenuItem<String>(
                            value: duration,
                            child: Text(duration),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedDuration = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _injuriesController,
                    decoration: const InputDecoration(
                      labelText: 'Heridas Sufridas',
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _postNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Notas Post-Combate',
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('¿El gallo sobrevivió?'),
                    subtitle: Text(
                      _survived
                          ? 'El gallo está activo.'
                          : 'El gallo se marcará como "Perdido en Combate".',
                    ),
                    value: _survived,
                    onChanged: (bool value) {
                      setState(() {
                        _survived = value;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveFight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isEditing
                            ? 'Actualizar Resultado'
                            : 'Programar Combate',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
