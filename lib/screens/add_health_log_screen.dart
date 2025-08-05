// lib/screens/add_health_log_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/services/health_service.dart'; // Importamos el servicio

class AddHealthLogScreen extends StatefulWidget {
  final String roosterId;

  const AddHealthLogScreen({super.key, required this.roosterId});

  @override
  State<AddHealthLogScreen> createState() => _AddHealthLogScreenState();
}

class _AddHealthLogScreenState extends State<AddHealthLogScreen> {
  // Controladores y variables para el formulario
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;

  // Opciones para el tipo de registro
  String? _selectedLogType = 'Vacunación'; // Valor por defecto
  final List<String> _logTypes = [
    'Vacunación',
    'Desparasitación',
    'Vitamina',
    'Tratamiento',
  ];

  final HealthService _healthService = HealthService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Inicializamos la fecha con el día de hoy por defecto para agilizar el registro
    _selectedDate = DateTime.now();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // No se pueden registrar cuidados a futuro
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- MÉTODO PARA GUARDAR EL REGISTRO (Lógica pendiente en el servicio) ---
  Future<void> _saveHealthLog() async {
    // Validación de campos
    if (_selectedDate == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa la Fecha y la Descripción.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // En el siguiente paso, crearemos este método en el servicio
      await _healthService.addHealthLog(
        roosterId: widget.roosterId,
        date: _selectedDate!,
        logType: _selectedLogType!,
        description: _descriptionController.text,
        notes: _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro de salud guardado.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Registro de Salud'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de Tipo de Registro
            DropdownButtonFormField<String>(
              value: _selectedLogType,
              decoration: const InputDecoration(
                labelText: 'Tipo de Registro *',
              ),
              items: _logTypes.map((String type) {
                return DropdownMenuItem<String>(value: type, child: Text(type));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedLogType = newValue;
                });
              },
            ),
            const SizedBox(height: 16),

            // Selector de Fecha
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

            // Campo de texto para Descripción
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (Producto, Tratamiento, etc.) *',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Campo de texto para Notas
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (Dosis, Observaciones, etc.)',
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            // Botón de Guardar
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
                    : const Text('Guardar Registro'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
