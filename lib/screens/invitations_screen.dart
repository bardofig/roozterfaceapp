// lib/screens/invitations_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roozterfaceapp/services/invitation_service.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final InvitationService _invitationService = InvitationService();
  bool _isLoading = false;

  Future<void> _handleAccept(String galleraId) async {
    setState(() => _isLoading = true);
    try {
      await _invitationService.acceptInvitation(galleraId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('¡Te has unido a la gallera!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDecline(String galleraId) async {
    setState(() => _isLoading = true);
    try {
      await _invitationService.declineInvitation(galleraId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitación rechazada.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Invitaciones'),
      ),
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot?>(
            stream: _invitationService.getInvitationsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null ||
                  !snapshot.data!.exists) {
                return _buildEmptyState();
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final Map<String, dynamic> pendingInvites =
                  data['pending_invitations'] ?? {};

              if (pendingInvites.isEmpty) {
                return _buildEmptyState();
              }

              final invites = pendingInvites.entries.toList();

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: invites.length,
                itemBuilder: (context, index) {
                  final galleraId = invites[index].key;
                  final inviteData =
                      invites[index].value as Map<String, dynamic>;
                  final inviterName = inviteData['inviterName'] ?? 'Un criador';
                  final galleraName =
                      inviteData['galleraName'] ?? 'una gallera';
                  final role = inviteData['role'] ?? 'miembro';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: Theme.of(context).textTheme.bodyLarge,
                              children: [
                                TextSpan(
                                  text: inviterName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(
                                    text:
                                        ' te ha invitado a unirte a su gallera '),
                                TextSpan(
                                  text: '"$galleraName"',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: ' con el rol de "$role".'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.red),
                                onPressed: () => _handleDecline(galleraId),
                                child: const Text('Rechazar'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _handleAccept(galleraId),
                                child: const Text('Aceptar'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No tienes invitaciones pendientes.',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }
}
