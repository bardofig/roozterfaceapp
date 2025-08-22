// lib/screens/gallera_management_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/models/user_model.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/services/gallera_service.dart';
import 'package:roozterfaceapp/utils/error_handler.dart';

class GalleraManagementScreen extends StatefulWidget {
  const GalleraManagementScreen({super.key});
  @override
  State<GalleraManagementScreen> createState() =>
      _GalleraManagementScreenState();
}

class _GalleraManagementScreenState extends State<GalleraManagementScreen> {
  final GalleraService _galleraService = GalleraService();
  final _galleraNameController = TextEditingController();
  String? _activeGalleraId;
  UserModel? _currentUserProfile;
  bool _isSavingName = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserDataProvider>(context, listen: false);
    _currentUserProfile = userProvider.userProfile;
    _activeGalleraId = _currentUserProfile?.activeGalleraId;
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
    setState(() => _isSavingName = true);
    try {
      await _galleraService.updateGalleraName(
        galleraId: _activeGalleraId!,
        newName: _galleraNameController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Nombre de la gallera actualizado.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error al guardar: ${ErrorHandler.getUserFriendlyMessage(e)}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingName = false);
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
                        .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(
                                role[0].toUpperCase() + role.substring(1))))
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
      await _galleraService.inviteMember(
        galleraId: _activeGalleraId!,
        invitedEmail: email,
        role: role,
      );
      messenger.showSnackBar(
        const SnackBar(
            content: Text("Invitación enviada con éxito."),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
            content: Text('Error: ${ErrorHandler.getUserFriendlyMessage(e)}'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _removeMember(String memberId, String memberName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Miembro'),
        content: Text(
            '¿Estás seguro de que quieres eliminar a "$memberName" de la gallera? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar')),
          TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm == true) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await _galleraService.removeMember(
          galleraId: _activeGalleraId!,
          memberId: memberId,
        );
        messenger.showSnackBar(
          SnackBar(
              content: Text('"$memberName" ha sido eliminado.'),
              backgroundColor: Colors.green),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
              content: Text(
                  'Error al eliminar: ${ErrorHandler.getUserFriendlyMessage(e)}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Mi Gallera')),
      body: _activeGalleraId == null
          ? const Center(child: Text("No hay una gallera activa seleccionada."))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nombre de la Gallera',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildGalleraNameEditor(),
                  const Divider(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Miembros',
                          style: Theme.of(context).textTheme.titleLarge),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Invitar'),
                        onPressed: _showInviteDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMembersList(),
                ],
              ),
            ),
    );
  }

  Widget _buildGalleraNameEditor() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _galleraService.getGalleraStream(_activeGalleraId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const TextField(
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Cargando nombre...'));
        }
        final currentName = snapshot.data?.get('name') ?? '';
        if (_galleraNameController.text != currentName) {
          _galleraNameController.text = currentName;
        }

        return TextField(
          controller: _galleraNameController,
          onSubmitted: (_) => _saveGalleraName(),
          decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Nombre',
              suffixIcon: _isSavingName
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(
                      icon: const Icon(Icons.save_outlined),
                      onPressed: _saveGalleraName)),
          textCapitalization: TextCapitalization.words,
        );
      },
    );
  }

  Widget _buildMembersList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream:
          _galleraService.getMemberDetailsStream(galleraId: _activeGalleraId!),
      builder: (context, membersSnapshot) {
        if (membersSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (membersSnapshot.hasError) {
          return Center(
              child:
                  Text("Error al cargar miembros: ${membersSnapshot.error}"));
        }

        final members = membersSnapshot.data ?? [];
        if (members.isEmpty) {
          return const Center(child: Text("No hay miembros en esta gallera."));
        }

        members.sort((a, b) {
          if (a['roleInGallera'] == 'propietario') return -1;
          if (b['roleInGallera'] == 'propietario') return 1;
          return (a['fullName'] ?? '').compareTo(b['fullName'] ?? '');
        });

        return Card(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final String role = member['roleInGallera'] ?? 'desconocido';
              final String memberId = member['uid'];
              final String memberName = member['fullName'] ?? 'Sin Nombre';
              final bool isOwner = memberId == _currentUserProfile?.uid;

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(memberName),
                subtitle: Text(member['email'] ?? 'Sin Email'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(
                        role[0].toUpperCase() + role.substring(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: isOwner
                          ? Colors.amber.shade200
                          : Colors.grey.shade300,
                    ),
                    if (!isOwner)
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: Colors.red.shade400),
                        tooltip: 'Eliminar miembro',
                        onPressed: () => _removeMember(memberId, memberName),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
