// lib/screens/gallera_management_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roozterfaceapp/models/user_model.dart';
import 'package:roozterfaceapp/services/gallera_service.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';
import 'package:roozterfaceapp/utils/string_extensions.dart'; // LA IMPORTACIÓN CLAVE

class GalleraManagementScreen extends StatefulWidget {
  const GalleraManagementScreen({super.key});
  @override
  State<GalleraManagementScreen> createState() =>
      _GalleraManagementScreenState();
}

class _GalleraManagementScreenState extends State<GalleraManagementScreen> {
  final _galleraNameController = TextEditingController();
  final GalleraService _galleraService = GalleraService();
  final RoosterService _roosterService = RoosterService();
  String? _activeGalleraId;
  bool _isSavingName = false;
  late Future<Map<String, dynamic>?> _loadDataFuture;

  @override
  void initState() {
    super.initState();
    _loadDataFuture = _loadInitialData();
  }

  Future<Map<String, dynamic>?> _loadInitialData() async {
    try {
      final userSnapshot = await _roosterService.getUserProfileStream().first;
      if (!userSnapshot.exists)
        throw Exception("Perfil de usuario no encontrado.");
      final userProfile = UserModel.fromFirestore(userSnapshot);
      _activeGalleraId = userProfile.activeGalleraId;
      if (_activeGalleraId == null)
        throw Exception("El usuario no tiene una gallera activa asignada.");
      final galleraSnapshot = await _galleraService
          .getGalleraStream(_activeGalleraId!)
          .first;
      if (!galleraSnapshot.exists)
        throw Exception("No se encontraron los datos de la gallera.");
      final galleraData = galleraSnapshot.data() as Map<String, dynamic>;
      _galleraNameController.text = galleraData['name'] ?? 'Sin Nombre';
      return galleraData;
    } catch (e) {
      print("Error cargando datos iniciales de la gallera: $e");
      throw Exception("No se pudieron cargar los datos de la gallera.");
    }
  }

  @override
  void dispose() {
    _galleraNameController.dispose();
    super.dispose();
  }

  Future<void> _saveGalleraName() async {
    if (_activeGalleraId == null || _galleraNameController.text.trim().isEmpty)
      return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSavingName = true;
    });
    try {
      await _galleraService.updateGalleraName(
        galleraId: _activeGalleraId!,
        newName: _galleraNameController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nombre de la gallera actualizado.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingName = false;
        });
      }
    }
  }

  void _showInviteDialog() {
    final emailController = TextEditingController();
    String selectedRole = 'cuidador';
    final roles = ['cuidador', 'editor'];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Invitar Miembro'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email del invitado',
                      hintText: 'usuario@email.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Asignar Rol'),
                    items: roles
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.capitalize()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (emailController.text.trim().isEmpty) return;
                    Navigator.of(context).pop();
                    _processInvitation(
                      emailController.text.trim(),
                      selectedRole,
                    );
                  },
                  child: const Text('Enviar Invitación'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processInvitation(String email, String role) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Procesando invitación...')),
    );
    try {
      final result = await _galleraService.inviteMember(
        galleraId: _activeGalleraId!,
        invitedEmail: email,
        role: role,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.data['message']),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Mi Gallera')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                "Error al cargar la información: ${snapshot.error ?? 'No hay datos.'}",
              ),
            );
          }
          final galleraData = snapshot.data!;
          final Map<String, dynamic> membersMap = galleraData['members'] ?? {};
          final List<String> memberIds = membersMap.keys.toList();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nombre de la Gallera',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Este es el nombre que verán los miembros que invites.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _galleraNameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Nombre',
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isSavingName
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.save_outlined),
                            onPressed: _saveGalleraName,
                            tooltip: 'Guardar Nombre',
                          ),
                  ],
                ),
                const Divider(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Miembros',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Invitar'),
                      onPressed: _showInviteDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<UserModel>>(
                  stream: _galleraService.getMembersProfilesStream(memberIds),
                  builder: (context, membersSnapshot) {
                    if (!membersSnapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final members = membersSnapshot.data!;
                    return Card(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final role = membersMap[member.uid] ?? 'desconocido';
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person_outline),
                            ),
                            title: Text(member.fullName),
                            subtitle: Text(member.email),
                            trailing: Chip(
                              label: Text(
                                role.capitalize(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: role == 'propietario'
                                  ? Colors.amber.shade200
                                  : Colors.grey.shade300,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
