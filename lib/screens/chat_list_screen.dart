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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Conversaciones'),
      ),
      // Usamos un color de fondo ligeramente diferente para que las Card resalten
      backgroundColor:
          Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getChatListStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            String errorMessage = 'Error al cargar las conversaciones.';
            if (snapshot.error is FirebaseException) {
              errorMessage =
                  'Error: ${(snapshot.error as FirebaseException).message}';
            }
            return Center(child: Text(errorMessage));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

          final chatDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
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
              // Este ID ahora es crucial para reabrir el chat correcto
              final String subjectRoosterId =
                  data['subjectRoosterId'] ?? chatDoc.id;

              return ChatListTile(
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
              );
            },
          );
        },
      ),
    );
  }
}
