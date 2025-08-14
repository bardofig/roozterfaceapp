// lib/services/chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roozterfaceapp/models/chat_message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String getChatRoomId(String otherUserId) {
    final currentUserId = _auth.currentUser!.uid;
    List<String> ids = [currentUserId, otherUserId];
    ids.sort();
    return ids.join('_');
  }

  /// Envía un mensaje y actualiza el resumen del chat.
  /// Ahora recibe el nombre del usuario actual como parámetro.
  Future<void> sendMessage({
    required String recipientId,
    required String messageText,
    required String subjectRoosterName,
    required String recipientName,
    required String currentUserName, // <-- EL COMANDANTE PROVEE ESTE DATO
  }) async {
    final currentUser = _auth.currentUser!;
    if (messageText.trim().isEmpty) return;

    final String chatRoomId = getChatRoomId(recipientId);

    final newMessage = ChatMessageModel(
      senderId: currentUser.uid,
      text: messageText.trim(),
      timestamp: Timestamp.now(),
    );

    final chatRoomRef = _firestore.collection('chats').doc(chatRoomId);
    final messageRef = chatRoomRef.collection('messages').doc();

    // Usamos una transacción para garantizar la consistencia de los datos
    await _firestore.runTransaction((transaction) async {
      final chatDoc = await transaction.get(chatRoomRef);

      final chatSummaryData = {
        'participants': [currentUser.uid, recipientId],
        'participantNames': {
          currentUser.uid: currentUserName,
          recipientId: recipientName,
        },
        'subjectRoosterName': subjectRoosterName,
        'lastMessageText': newMessage.text,
        'lastMessageTimestamp': newMessage.timestamp,
        'lastMessageSenderId': currentUser.uid,
      };

      if (!chatDoc.exists) {
        transaction.set(chatRoomRef, chatSummaryData);
        // También marcamos como leído por el emisor al crear
        transaction.set(
            chatRoomRef,
            {
              'lastMessageReadBy': {currentUser.uid: newMessage.timestamp}
            },
            SetOptions(merge: true));
      } else {
        transaction.update(chatRoomRef, chatSummaryData);
      }

      transaction.set(messageRef, newMessage.toMap());
    });
  }

  /// Actualiza el timestamp del último mensaje leído por el usuario actual.
  Future<void> markChatAsRead(String chatRoomId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _firestore.collection('chats').doc(chatRoomId).set({
      'lastMessageReadBy': {currentUserId: Timestamp.now()},
    }, SetOptions(merge: true));
  }

  /// Obtiene el stream de mensajes para una sala de chat específica.
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Obtiene todas las conversaciones en las que participa el usuario actual.
  Stream<QuerySnapshot> getChatListStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return const Stream.empty();

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }
}
