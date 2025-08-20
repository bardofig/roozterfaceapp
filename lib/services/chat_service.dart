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

  Future<void> sendMessage({
    required String recipientId,
    required String messageText,
    required String subjectRoosterName,
    required String recipientName,
    required String currentUserName,
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

    await _firestore.runTransaction((transaction) async {
      final chatDoc = await transaction.get(chatRoomRef);

      // Usamos 'participants' consistentemente
      Map<String, dynamic> chatSummaryData = {
        'participants': [currentUser.uid, recipientId],
        'participantNames': {
          currentUser.uid: currentUserName,
          recipientId: recipientName,
        },
        'subjectRoosterName': subjectRoosterName,
        'lastMessageText': newMessage.text,
        'lastMessageTimestamp': newMessage.timestamp,
        'lastMessageSenderId': currentUser.uid,
        'deleted_up_to': {
          // Asegura que el chat reaparezca para el otro usuario si estaba borrado para él
          recipientId: FieldValue.delete(),
        },
      };

      if (!chatDoc.exists) {
        transaction.set(chatRoomRef, chatSummaryData);
        transaction.set(
            chatRoomRef,
            {
              'lastMessageReadBy': {currentUser.uid: newMessage.timestamp}
            },
            SetOptions(merge: true));
      } else {
        transaction.set(chatRoomRef, chatSummaryData, SetOptions(merge: true));
      }

      transaction.set(messageRef, newMessage.toMap());
    });
  }

  Future<void> markChatAsRead(String chatRoomId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _firestore.collection('chats').doc(chatRoomId).set({
      'lastMessageReadBy': {currentUserId: FieldValue.serverTimestamp()},
    }, SetOptions(merge: true));
  }

  Future<void> deleteChatForCurrentUser(String chatRoomId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final chatRoomRef = _firestore.collection('chats').doc(chatRoomId);

    // En lugar de borrar, marcamos el chat como oculto para el usuario actual.
    // Esto es más seguro y reversible.
    await chatRoomRef.update({
      'hidden_for': FieldValue.arrayUnion([currentUserId])
    });
  }

  Stream<DocumentSnapshot> getChatRoomStream(String chatRoomId) {
    return _firestore.collection('chats').doc(chatRoomId).snapshots();
  }

  Stream<QuerySnapshot> getMessages(String chatRoomId, Timestamp? deletedUpTo) {
    Query query = _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true);

    if (deletedUpTo != null) {
      query = query.where('timestamp', isGreaterThan: deletedUpTo);
    }

    return query.snapshots();
  }

  // --- MÉTODO CORREGIDO ---
  Stream<QuerySnapshot> getChatListStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return const Stream.empty();

    // La consulta ahora es disciplinada. Obedece la ley de las reglas de seguridad.
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }
}
