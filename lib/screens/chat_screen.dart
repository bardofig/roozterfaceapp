// lib/screens/chat_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/models/chat_message_model.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String subjectRoosterId;
  final String subjectRoosterName;

  const ChatScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    required this.subjectRoosterId,
    required this.subjectRoosterName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final String _chatRoomId;

  @override
  void initState() {
    super.initState();
    _chatRoomId = _chatService.getChatRoomId(widget.recipientId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatService.markChatAsRead(_chatRoomId);
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      final currentUserName =
          Provider.of<UserDataProvider>(context, listen: false)
                  .userProfile
                  ?.fullName ??
              'Usuario Desconocido';

      _chatService.sendMessage(
        recipientId: widget.recipientId,
        messageText: _messageController.text,
        subjectRoosterName: widget.subjectRoosterName,
        recipientName: widget.recipientName,
        currentUserName: currentUserName,
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conversación con ${widget.recipientName}'),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            child: Center(
              child: Text(
                'Conversación sobre: "${widget.subjectRoosterName}"',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: _buildMessagesListContainer(),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  // --- LA ARQUITECTURA FINAL ---
  Widget _buildMessagesListContainer() {
    // 1. El StreamBuilder padre escucha el documento de resumen del chat.
    return StreamBuilder<DocumentSnapshot>(
      stream: _chatService.getChatRoomStream(_chatRoomId),
      builder: (context, chatSnapshot) {
        if (!chatSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        Timestamp? myDeleteMarker;
        if (chatSnapshot.data!.exists) {
          final data = chatSnapshot.data!.data() as Map<String, dynamic>;
          final Map<String, dynamic> deletedUpTo = data['deleted_up_to'] ?? {};
          myDeleteMarker = deletedUpTo[_auth.currentUser!.uid];
        }

        // 2. CON la información del marcador, construimos el StreamBuilder hijo.
        return StreamBuilder<QuerySnapshot>(
          stream: _chatService.getMessages(_chatRoomId, myDeleteMarker),
          builder: (context, messagesSnapshot) {
            if (messagesSnapshot.hasError) {
              return const Center(child: Text('Error al cargar mensajes.'));
            }
            if (messagesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!messagesSnapshot.hasData ||
                messagesSnapshot.data!.docs.isEmpty) {
              return Center(
                  child: Text(myDeleteMarker != null
                      ? 'No hay mensajes nuevos.'
                      : 'Inicia la conversación.'));
            }

            return ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(8.0),
              itemCount: messagesSnapshot.data!.docs.length,
              itemBuilder: (context, index) =>
                  _buildMessageItem(messagesSnapshot.data!.docs[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    final message = ChatMessageModel.fromFirestore(doc);
    final isCurrentUser = message.senderId == _auth.currentUser!.uid;

    var alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final Color currentUserBubbleColor =
        isDarkMode ? const Color(0xFF005C4B) : const Color(0xFFE7FFDB);

    final Color currentUserTextColor =
        isDarkMode ? Colors.white.withOpacity(0.9) : Colors.black87;

    return Container(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? currentUserBubbleColor
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 16.0,
            color: isCurrentUser
                ? currentUserTextColor
                : Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 3,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Escribe tu mensaje...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(fontSize: 16.0),
            ),
          ),
          IconButton(
            icon:
                Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
