// lib/core/services/chat_service.dart
//
// PURPOSE: Manages real-time chat between a client and a worker.
// Each conversation is stored in Firestore under:
//   /chats/{chatId}/messages/{messageId}
//
// The chatId is a deterministic combination of both UIDs (sorted alphabetically)
// so the same conversation is always found regardless of who opens it first.
// This implements the "Chat System Algorithm" from Section 3.1.

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Chat ID Generation ────────────────────────────────────────────────────

  /// Creates a unique, deterministic chat room ID for two users.
  /// Sorted alphabetically so uid1+uid2 and uid2+uid1 produce the same ID.
  String getChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // ─── Send Message ──────────────────────────────────────────────────────────

  /// Sends a message and updates the chat metadata document for listing chats.
  Future<void> sendMessage({
    required String senderUid,
    required String senderName,
    required String receiverUid,
    required String receiverName,
    required String text,
  }) async {
    final chatId = getChatId(senderUid, receiverUid);
    final message = ChatMessage(
      senderId: senderUid,
      text: text,
      timestamp: DateTime.now(),
    );

    final batch = _firestore.batch();

    // Add message to subcollection
    final msgRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    batch.set(msgRef, message.toMap());

    // Update chat metadata (for chat list screen – shows last message preview)
    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.set(chatRef, {
      'participants': [senderUid, receiverUid],
      'participantNames': {senderUid: senderName, receiverUid: receiverName},
      'lastMessage': text,
      'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      'lastSenderId': senderUid,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // ─── Listen for Messages ───────────────────────────────────────────────────

  /// Returns a real-time stream of messages in the conversation,
  /// ordered by timestamp ascending (oldest first).
  Stream<List<ChatMessage>> getMessages({
    required String uid1,
    required String uid2,
  }) {
    final chatId = getChatId(uid1, uid2);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data()))
            .toList());
  }

  // ─── Mark Messages as Read ────────────────────────────────────────────────

  Future<void> markMessagesAsRead({
    required String currentUserUid,
    required String otherUserUid,
  }) async {
    final chatId = getChatId(currentUserUid, otherUserUid);
    final unread = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isEqualTo: otherUserUid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}