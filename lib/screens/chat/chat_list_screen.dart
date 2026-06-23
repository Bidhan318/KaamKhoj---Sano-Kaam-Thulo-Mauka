

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  // ── Firestore query ──────────────────────────────────────────────────────

  Stream<List<_ChatPreview>> _chatsStream(String myUid) {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .handleError((e) {
      debugPrint('CHAT LIST ERROR: $e');
    })
        .map((snapshot) => snapshot.docs
        .map((doc) => _ChatPreview.fromDoc(doc, myUid))
        .toList());
  }
  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 && now.day == dt.day) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays == 1 || (diff.inHours < 48 && now.day != dt.day)) {
      return 'Yesterday';
    }
    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final myUid = context.read<AuthProvider>().user!.uid;
    final myName = context.read<AuthProvider>().user!.name;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Messages'),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: StreamBuilder<List<_ChatPreview>>(
          stream: _chatsStream(myUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final chats = snapshot.data ?? [];

            if (chats.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 56, color: AppColors.textSecondary),
                    SizedBox(height: 12),
                    Text('No conversations yet',
                        style: TextStyle(
                            fontSize: 16, color: AppColors.textSecondary)),
                    SizedBox(height: 4),
                    Text('Start chatting from a worker or job profile',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: chats.length,
              itemBuilder: (context, i) {
                final chat = chats[i];
                final isMe = chat.lastSenderId == myUid;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.divider, width: 1),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      hoverColor: AppColors.primary.withValues(alpha: 0.15),
                      highlightColor: AppColors.primary.withValues(alpha: 0.1),
                      splashColor: AppColors.primary.withValues(alpha: 0.2),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              otherUid: chat.otherUid,
                              otherName: chat.otherName,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            _Avatar(name: chat.otherName),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chat.otherName,
                                    style: TextStyle(
                                      fontWeight: chat.hasUnread && !isMe
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isMe
                                        ? 'You: ${chat.lastMessage}'
                                        : chat.lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: chat.hasUnread && !isMe
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                      fontWeight: chat.hasUnread && !isMe
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatTime(chat.lastMessageTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: chat.hasUnread && !isMe
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontWeight: chat.hasUnread && !isMe
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (chat.hasUnread && !isMe) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Avatar widget ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  Color _bgColor() {
    if (name.trim().isEmpty) return const Color(0xFFE8F0FE);
    final colors = [
      const Color(0xFFE8F0FE),
      const Color(0xFFFCE8E6),
      const Color(0xFFE6F4EA),
      const Color(0xFFFEF3E2),
      const Color(0xFFF3E8FD),
    ];
    return colors[name.trim().codeUnitAt(0) % colors.length];
  }

  Color _textColor() {
    if (name.trim().isEmpty) return const Color(0xFF1A73E8);
    final colors = [
      const Color(0xFF1A73E8),
      const Color(0xFFC5221F),
      const Color(0xFF1E7E34),
      const Color(0xFFB06000),
      const Color(0xFF6C2FA0),
    ];
    return colors[name.trim().codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final trimName = name.trim();
    final initials = trimName.isEmpty
        ? '?'
        : trimName.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();
    return CircleAvatar(
      radius: 24,
      backgroundColor: _bgColor(),
      child: Text(
        initials,
        style: TextStyle(
            color: _textColor(), fontWeight: FontWeight.w500, fontSize: 14),
      ),
    );
  }
}

// ── Data class ───────────────────────────────────────────────────────────────

class _ChatPreview {
  final String chatId;
  final String otherUid;
  final String otherName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastSenderId;
  final bool hasUnread;

  const _ChatPreview({
    required this.chatId,
    required this.otherUid,
    required this.otherName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastSenderId,
    required this.hasUnread,
  });

  factory _ChatPreview.fromDoc(DocumentSnapshot doc, String myUid) {
    final data = doc.data() as Map<String, dynamic>;

    // Find the other participant's UID
    final participants = List<String>.from(data['participants'] ?? []);
    final otherUid = participants.firstWhere(
          (uid) => uid != myUid,
      orElse: () => '',
    );

    // Resolve other person's name from participantNames map (requires the
    // 1-line edit in chat_service.dart sendMessage() described at top of file).
    // Falls back to 'Unknown' if the field isn't present yet.
    final participantNames =
    Map<String, dynamic>.from(data['participantNames'] ?? {});
    final otherName = participantNames[otherUid] as String? ?? 'Unknown';

    final lastMessageTime =
        (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now();

    // hasUnread: true when the last message wasn't sent by me.
    // A proper unread count can be added later via a subcollection query,
    // but this gives a simple dot indicator without extra reads.
    final lastSenderId = data['lastSenderId'] as String? ?? '';
    final hasUnread = lastSenderId != myUid;

    return _ChatPreview(
      chatId: doc.id,
      otherUid: otherUid,
      otherName: otherName,
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageTime: lastMessageTime,
      lastSenderId: lastSenderId,
      hasUnread: hasUnread,
    );
  }
}