// lib/screens/add_health_log_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/models/health_log_model.dart';
import 'package:roozterfaceapp/services/health_service.dart';

class AddHealthLogScreen extends StatefulWidget {
  final String roosterId;
  final HealthLogModel? logToEdit; // Parámetro opcional para modo edición

  const AddHealthLogScreen({
    super.key,
    required this.roosterId,
    this.logToEdit,
  });

  @override
  State<AddHealthLogScreen> createState() => _AddHealthLogScreenState();
}

class _AddHealthLogScreenState extends State<AddHealthLogScreen> {
  // Controladores
  final _productNameController = TextEditingController();
  final _conditionController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  // Variables de estado
  DateTime? _selectedDate;
  String? _selectedLogCategory;
  final List<String> _logCategories = [
    'Vacunación',
    'Desparasitación',
    'Suplemento/Vitamina',
    'Enfermedad/Tratamiento',
  ];
  String? _selectedIllness;
  final List<String> _commonIllnesses = [
    'Corisa Infecciosa',
    'Cólera Aviar',
    'Colibacilosis',
    'Micoplasmosis',
    'Salmonelosis',
    'Tuberculosis',
    'Bronquitis Infecciosa',
    'Enfermedad de Marek',
    'Enfermedad de Newcastle',
    'Viruela Aviar',
    'Ascaridiosis (Parásitos Int.)',
    'Coccidiosis',
    'Parásitos Externos (Piojo/Ácaro)',
    'Herida de Combate',
    'Otra...',
  ];

  final HealthService _healthService = HealthService();
  bool _isSaving = false;
  bool get _isEditing => widget.logToEdit != null;

  @override
  void initState() {
    super.initState();
    // --- LÓGICA DE INICIALIZACIÓN CORREGIDA ---
    if (_isEditing) {
      // Si estamos editando, llenamos los campos con los datos del registro existente
      final log = widget.logToEdit!;
      _productNameController.text = log.productName;
      _dosageController.text = log.dosage ?? '';
      _notesController.text = log.notes;
      _selectedDate = log.date;
      _selectedLogCategory = log.logCategory;

      // Lógica para manejar la enfermedad/condición
      if (log.illnessOrCondition != null &&
          log.illnessOrCondition!.isNotEmpty) {
        // Comprobamos si la condición guardada está en nuestra lista de enfermedades comunes
        if (_commonIllnesses.contains(log.illnessOrCondition)) {
          _selectedIllness = log.illnessOrCondition;
        } else {
          // Si no está en la lista, significa que fue una entrada manual
          _selectedIllness = 'Otra...';
          _conditionController.text = log.illnessOrCondition!;
        }
      }
    } else {
      // Valores por defecto al crear un nuevo registro
      _selectedLogCategory = 'Vacunación';
      _selectedDate = DateTime.now();
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

  Future<void> _saveHealthLog() async {
    if (_selectedDate == null || _productNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, completa la Fecha y el Nombre del Producto.',
          ),
        ),
      );
      return;
    }

    String? conditionToSave;
    if (_selectedLogCategory == 'Enfermedad/Tratamiento') {
      conditionToSave = (_selectedIllness == 'Otra...')
          ? _conditionController.text
          : _selectedIllness;
      if (conditionToSave == null || conditionToSave.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecciona o especifica una condición.'),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        await _healthService.updateHealthLog(
          roosterId: widget.roosterId,
          logId: widget.logToEdit!.id,
          date: _selectedDate!,
          logCategory: _selectedLogCategory!,
          productName: _productNameController.text,
          illnessOrCondition: conditionToSave,
          dosage: _dosageController.text,
          notes: _notesController.text,
        );
      } else {
        await _healthService.addHealthLog(
          roosterId: widget.roosterId,
          date: _selectedDate!,
          logCategory: _selectedLogCategory!,
          productName: _productNameController.text,
          illnessOrCondition: conditionToSave,
          dosage: _dosageController.text,
          notes: _notesController.text,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro de salud guardado.')),
        );
        Navigator.of(context).pop(); // Cierra el formulario de edición
        if (_isEditing) {
          Navigator.of(context).pop(); // Cierra también la pantalla de detalles
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
        title: Text(
          _isEditing ? 'Editar Registro de Salud' : 'Añadir Registro de Salud',
        ),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedLogCategory,
              decoration: const InputDecoration(
                labelText: 'Categoría del Registro *',
              ),
              items: _logCategories
                  .map(
                    (String category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedLogCategory = newValue;
                  if (newValue != 'Enfermedad/Tratamiento') {
                    _selectedIllness = null;
                    _conditionController.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Fecha de Aplicación *'
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
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Producto/Tratamiento *',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            if (_selectedLogCategory == 'Enfermedad/Tratamiento')
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedIllness,
                    decoration: const InputDecoration(
                      labelText: 'Enfermedad o Condición *',
                    ),
                    items: _commonIllnesses
                        .map(
                          (String illness) => DropdownMenuItem<String>(
                            value: illness,
                            child: Text(illness),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedIllness = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedIllness == 'Otra...')
                    TextField(
                      controller: _conditionController,
                      decoration: const InputDecoration(
                        labelText: 'Especificar otra condición *',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  if (_selectedIllness == 'Otra...') const SizedBox(height: 16),
                ],
              ),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosis (ej: 0.5 ml, 1 pastilla)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notas Adicionales'),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveHealthLog,
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
