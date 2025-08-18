// lib/screens/area_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/models/area_model.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/services/area_service.dart';

class AreaManagementScreen extends StatefulWidget {
  const AreaManagementScreen({super.key});

  @override
  State<AreaManagementScreen> createState() => _AreaManagementScreenState();
}

class _AreaManagementScreenState extends State<AreaManagementScreen> {
  final AreaService _areaService = AreaService();

  // Lista de categorías predefinidas para facilitar la organización.
  final List<String> _areaCategories = [
    'Entrenamiento',
    'Cría',
    'Recuperación',
    'Crecimiento',
    'Otra',
  ];

  void _showAreaDialog({AreaModel? areaToEdit}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: areaToEdit?.name ?? '');
    final descController =
        TextEditingController(text: areaToEdit?.description ?? '');
    String selectedCategory = areaToEdit?.category ?? 'Otra';
    final bool isEditing = areaToEdit != null;

    showDialog(
      context: context,
      builder: (context) {
        final activeGalleraId =
            Provider.of<UserDataProvider>(context, listen: false)
                .userProfile!
                .activeGalleraId!;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Área' : 'Crear Nueva Área'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Nombre del Área'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'El nombre es obligatorio'
                                : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration:
                            const InputDecoration(labelText: 'Categoría'),
                        items: _areaCategories
                            .map((cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedCategory = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                            labelText: 'Descripción (Opcional)'),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        if (isEditing) {
                          await _areaService.updateArea(
                            galleraId: activeGalleraId,
                            areaId: areaToEdit.id,
                            name: nameController.text,
                            category: selectedCategory,
                            description: descController.text,
                          );
                        } else {
                          await _areaService.addArea(
                            galleraId: activeGalleraId,
                            name: nameController.text,
                            category: selectedCategory,
                            description: descController.text,
                          );
                        }
                        if (mounted) Navigator.of(context).pop();
                      } catch (e) {
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red),
                          );
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeGalleraId =
        Provider.of<UserDataProvider>(context).userProfile?.activeGalleraId;
    if (activeGalleraId == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Gestionar Áreas')),
          body: const Center(child: Text('No hay una gallera activa')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Áreas de la Gallera'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAreaDialog,
        child: const Icon(Icons.add),
        tooltip: 'Añadir Nueva Área',
      ),
      body: StreamBuilder<List<AreaModel>>(
        stream: _areaService.getAreasStream(activeGalleraId),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));

          final areas = snapshot.data!;
          if (areas.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                    'No has definido ninguna área.\nPresiona el botón "+" para crear la primera.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ),
            );
          }

          return ListView.builder(
            itemCount: areas.length,
            itemBuilder: (context, index) {
              final area = areas[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(area.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(area.category),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showAreaDialog(areaToEdit: area),
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: Colors.red.shade400),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirmar Borrado'),
                              content: Text(
                                  '¿Estás seguro de que quieres borrar el área "${area.name}"?'),
                              actions: [
                                TextButton(
                                    child: const Text('Cancelar'),
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false)),
                                TextButton(
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.red),
                                    child: const Text('Borrar'),
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true)),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            _areaService.deleteArea(
                                galleraId: activeGalleraId, areaId: area.id);
                          }
                        },
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
