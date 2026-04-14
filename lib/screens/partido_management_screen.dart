// lib/screens/partido_management_screen.dart

import 'package:flutter/material.dart';
import 'package:roozterfaceapp/models/partido_model.dart';
import 'package:roozterfaceapp/services/partido_service.dart';

class PartidoManagementScreen extends StatefulWidget {
  final String partidoId;
  const PartidoManagementScreen({super.key, required this.partidoId});

  @override
  State<PartidoManagementScreen> createState() => _PartidoManagementScreenState();
}

class _PartidoManagementScreenState extends State<PartidoManagementScreen> {
  final PartidoService _partidoService = PartidoService();
  final _emailController = TextEditingController();

  Future<void> _showInviteDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invitar Socio'),
        content: TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            hintText: 'ejemplo@gmail.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final email = _emailController.text.trim();
              if (email.isEmpty) return;
              
              Navigator.pop(context);
              try {
                await _partidoService.inviteMemberByEmail(
                  partidoId: widget.partidoId,
                  email: email,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invitación enviada y procesada.'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
              _emailController.clear();
            },
            child: const Text('Invitar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PartidoModel?>(
      stream: _partidoService.getActivePartidoStream(widget.partidoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final partido = snapshot.data;
        if (partido == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('No se encontró información del partido.')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(partido.name),
            actions: [
              IconButton(icon: const Icon(Icons.person_add_outlined), onPressed: _showInviteDialog),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header con Logo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'partido_logo',
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.amber,
                          backgroundImage: partido.logoUrl != null ? NetworkImage(partido.logoUrl!) : null,
                          child: partido.logoUrl == null ? const Icon(Icons.shield, size: 50, color: Colors.white) : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        partido.name,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Text('Equipo Competitivo', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.group, color: Colors.amber),
                          SizedBox(width: 8),
                          Text('Socios del Equipo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: partido.members.length,
                        itemBuilder: (context, index) {
                          final uid = partido.members.keys.elementAt(index);
                          final role = partido.members[uid];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text('Miembro ID: ...${uid.substring(uid.length - 4)}'), // Prototipo: En producción se jalaría el nombre real
                              subtitle: Text(role?.toUpperCase() ?? ''),
                              trailing: role == 'propietario' 
                                ? const Chip(label: Text('DUEÑO'), backgroundColor: Colors.amber)
                                : IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () => _partidoService.removeMember(partidoId: partido.id, memberId: uid),
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
