// lib/widgets/chat_list_tile.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListTile extends StatelessWidget {
  final DocumentSnapshot chatDocument;
  final VoidCallback onTap;

  const ChatListTile({
    super.key,
    required this.chatDocument,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = chatDocument.data() as Map<String, dynamic>;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return const SizedBox.shrink();

    final List<String> participants =
        List<String>.from(data['participants'] ?? []);
    final otherUserId = participants.firstWhere((id) => id != currentUser.uid,
        orElse: () => '');

    final Map<String, dynamic> participantNames =
        data['participantNames'] ?? {};
    final String otherUserName =
        participantNames[otherUserId] ?? 'Usuario Desconocido';
    final String subjectRoosterName =
        data['subjectRoosterName'] ?? 'un ejemplar';

    final String lastMessage =
        data['lastMessageText'] ?? 'Inicia la conversación...';
    final Timestamp? lastMessageTimestamp = data['lastMessageTimestamp'];
    final Map<String, dynamic> lastReadByMap = data['lastMessageReadBy'] ?? {};
    final Timestamp? myLastReadTimestamp = lastReadByMap[currentUser.uid];

    final bool wasLastMessageMine =
        data['lastMessageSenderId'] == currentUser.uid;

    // --- LÓGICA DEL INDICADOR "NO LEÍDO" ---
    bool isUnread = false;
    if (!wasLastMessageMine && lastMessageTimestamp != null) {
      if (myLastReadTimestamp == null ||
          lastMessageTimestamp.compareTo(myLastReadTimestamp) > 0) {
        // Si el último mensaje no es mío, y...
        // ...nunca he leído este chat, O el último mensaje es más nuevo que mi última lectura.
        isUnread = true;
      }
    }

    String timeAgoString = 'Ahora';
    if (lastMessageTimestamp != null) {
      timeago.setLocaleMessages('es', timeago.EsMessages());
      timeAgoString =
          timeago.format(lastMessageTimestamp.toDate(), locale: 'es');
    }

    final String messagePrefix = wasLastMessageMine ? 'Tú: ' : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      elevation: isUnread ? 4 : 1, // Resalta la tarjeta si no está leída
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Text(
            otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondaryContainer),
          ),
        ),
        title: Text(
          otherUserName,
          style: TextStyle(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sobre: $subjectRoosterName',
              style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.secondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$messagePrefix$lastMessage',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  color: isUnread
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeAgoString,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            // El indicador visual
            if (isUnread)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(
                  width: 12,
                  height: 12), // Placeholder para mantener la alineación
          ],
        ),
      ),
    );
  }
}
