// lib/screens/add_fight_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/data/options_data.dart';
import 'package:roozterfaceapp/models/fight_model.dart';
import 'package:roozterfaceapp/services/fight_service.dart';

class AddFightScreen extends StatefulWidget {
  final String galleraId;
  final String roosterId;
  final FightModel? fightToEdit;

  const AddFightScreen({
    super.key,
    required this.galleraId,
    required this.roosterId,
    this.fightToEdit,
  });

  @override
  State<AddFightScreen> createState() => _AddFightScreenState();
}

class _AddFightScreenState extends State<AddFightScreen> {
  final _locationController = TextEditingController();
  final _opponentController = TextEditingController();
  final _prepNotesController = TextEditingController();
  final _postNotesController = TextEditingController();
  final _injuriesController = TextEditingController();
  final _netProfitController = TextEditingController();

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
      _selectedResult = fight.result;
      _survived = fight.survived ?? true;
      _selectedWeaponType = fight.weaponType;
      _selectedDuration = fight.fightDuration;
      _injuriesController.text = fight.injuriesSustained ?? '';
      if (fight.netProfit != null) {
        _netProfitController.text =
            fight.netProfit!.toStringAsFixed(2).replaceAll('.00', '');
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _opponentController.dispose();
    _prepNotesController.dispose();
    _postNotesController.dispose();
    _injuriesController.dispose();
    _netProfitController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null)
      setState(() {
        _selectedDate = picked;
      });
  }

  Future<void> _saveFight() async {
    if (_selectedDate == null || _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('La Fecha y el Lugar son obligatorios.')));
      return;
    }
    if (_isEditing &&
        (_opponentController.text.trim().isEmpty || _selectedResult == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'El Oponente y el Resultado son obligatorios para completar un evento.')));
      return;
    }
    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        final netProfit = _netProfitController.text.trim().isEmpty
            ? null
            : double.tryParse(_netProfitController.text);

        await _fightService.updateFight(
          galleraId: widget.galleraId,
          roosterId: widget.roosterId,
          fightId: widget.fightToEdit!.id,
          date: _selectedDate!,
          location: _locationController.text.trim(),
          preparationNotes: _prepNotesController.text.trim(),
          opponent: _opponentController.text.trim(),
          result: _selectedResult,
          postFightNotes: _postNotesController.text.trim(),
          survived: _survived,
          weaponType: _selectedWeaponType,
          fightDuration: _selectedDuration,
          injuriesSustained: _injuriesController.text.trim(),
          netProfit: netProfit,
        );
      } else {
        await _fightService.addFight(
          galleraId: widget.galleraId,
          roosterId: widget.roosterId,
          date: _selectedDate!,
          location: _locationController.text.trim(),
          preparationNotes: _prepNotesController.text.trim(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evento de combate guardado.')));
        Navigator.of(context).pop();
        if (_isEditing) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: ${e.toString()}')));
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text(
                      _selectedDate == null
                          ? 'Fecha del Evento *'
                          : 'Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                      style: const TextStyle(fontSize: 16))),
              TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Seleccionar')),
            ]),
            const SizedBox(height: 16),
            TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Lugar / Derby *'),
                textCapitalization: TextCapitalization.words),
            const SizedBox(height: 16),
            TextField(
                controller: _prepNotesController,
                decoration:
                    const InputDecoration(labelText: 'Notas de Preparación'),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences),
            if (_isEditing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 32),
                  Text("Resultado del Combate",
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _opponentController,
                      decoration: const InputDecoration(
                          labelText: 'Oponente (Placa o Descripción) *'),
                      textCapitalization: TextCapitalization.words),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                      value: _selectedResult,
                      decoration:
                          const InputDecoration(labelText: 'Resultado *'),
                      items: _results
                          .map((r) => DropdownMenuItem<String>(
                              value: r, child: Text(r)))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedResult = newValue;
                        });
                      }),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                      value: _selectedWeaponType,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Arma Utilizada'),
                      items: weaponTypeOptions
                          .map((w) => DropdownMenuItem<String>(
                              value: w, child: Text(w)))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedWeaponType = newValue;
                        });
                      }),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                      value: _selectedDuration,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'Duración de la Pelea'),
                      items: fightDurationOptions
                          .map((d) => DropdownMenuItem<String>(
                              value: d, child: Text(d)))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedDuration = newValue;
                        });
                      }),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _injuriesController,
                      decoration:
                          const InputDecoration(labelText: 'Heridas Sufridas'),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _postNotesController,
                      decoration: const InputDecoration(
                          labelText: 'Notas Post-Combate'),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences),
                  const SizedBox(height: 16),
                  SwitchListTile(
                      title: const Text('¿El ejemplar sobrevivió?'),
                      value: _survived,
                      onChanged: (bool value) {
                        setState(() {
                          _survived = value;
                        });
                      },
                      activeColor: Colors.green),
                  const Divider(height: 32),
                  Text("Resultado Financiero",
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _netProfitController,
                    decoration: const InputDecoration(
                        labelText: 'Ganancia / Pérdida Neta (\$)',
                        hintText: 'Ej: 500 para ganancia, -100 para pérdida',
                        prefixText: '\$ '),
                    keyboardType: const TextInputType.numberWithOptions(
                        signed: true, decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveFight,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isEditing
                        ? 'Actualizar Resultado'
                        : 'Programar Combate'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
