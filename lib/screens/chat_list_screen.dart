// lib/screens/chat_list_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roozterfaceapp/screens/chat_screen.dart';
import 'package:roozterfaceapp/services/chat_service.dart';
import 'package:roozterfaceapp/widgets/chat_list_tile.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _confirmAndHideChat(DocumentSnapshot chatDoc) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Eliminar Conversación"),
          content: const Text(
              "¿Estás seguro de que quieres eliminar esta conversación de tu bandeja de entrada? No se eliminará para la otra persona."),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _chatService.deleteChatForCurrentUser(chatDoc.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Conversación eliminada.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Conversaciones'),
      ),
      backgroundColor:
          Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getChatListStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text(
                    'Error al cargar las conversaciones: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUserId = _auth.currentUser?.uid;
          if (currentUserId == null) {
            return const Center(
                child: Text(
                    "No se pudo verificar el usuario. Por favor, reinicia sesión."));
          }

          final visibleChatDocs = snapshot.data?.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final participants =
                    List<String>.from(data['participants'] ?? []);
                final hiddenFor = List<String>.from(data['hidden_for'] ?? []);
                final belongsToMe = participants.contains(currentUserId);
                final isHidden = hiddenFor.contains(currentUserId);
                return belongsToMe && !isHidden;
              }).toList() ??
              [];

          if (visibleChatDocs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No tienes conversaciones activas.\nInicia una desde el Mercado de Ejemplares.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            itemCount: visibleChatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = visibleChatDocs[index];
              final data = chatDoc.data() as Map<String, dynamic>;

              final List<String> participants =
                  List<String>.from(data['participants'] ?? []);
              final otherUserId = participants.firstWhere(
                  (id) => id != _auth.currentUser!.uid,
                  orElse: () => '');

              final Map<String, dynamic> participantNames =
                  data['participantNames'] ?? {};
              final String otherUserName =
                  participantNames[otherUserId] ?? 'Usuario';

              final String subjectRoosterName =
                  data['subjectRoosterName'] ?? 'un ejemplar';
              final String subjectRoosterId = data['subjectRoosterId'] ?? '';

              return Dismissible(
                key: Key(chatDoc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red.shade700,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete_forever, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  await _confirmAndHideChat(chatDoc);
                  return false;
                },
                child: ChatListTile(
                  chatDocument: chatDoc,
                  onTap: () {
                    if (otherUserId.isEmpty) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          recipientId: otherUserId,
                          recipientName: otherUserName,
                          subjectRoosterId: subjectRoosterId,
                          subjectRoosterName: subjectRoosterName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
