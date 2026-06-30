// lib/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/chat_service.dart';
import '../../models/worker_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/profile_image_helper.dart';

class ChatScreen extends StatefulWidget {
  // Works for BOTH directions:
  // Client → Worker: pass worker object
  // Worker → Client: pass otherUid + otherName directly
  final WorkerModel? worker;
  final String? otherUid;
  final String? otherName;

  const ChatScreen({
    super.key,
    this.worker,         // Client tapping a worker
    this.otherUid,       // Worker contacting a client
    this.otherName,
  }) : assert(worker != null || otherUid != null,
            'Provide either worker or otherUid');

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late String _myUid;
  late String _otherUid;
  late String _otherName;
  late String _otherAvatarLetter;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _myUid = auth.user!.uid;

    // Resolve other party details
    if (widget.worker != null) {
      _otherUid = widget.worker!.uid;
      _otherName = widget.worker!.name;
    } else {
      _otherUid = widget.otherUid!;
      _otherName = widget.otherName ?? 'User';
    }
    _otherAvatarLetter = _otherName.isNotEmpty ? _otherName[0].toUpperCase() : '?';

    _chatService.markMessagesAsRead(
      currentUserUid: _myUid,
      otherUserUid: _otherUid,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final auth = context.read<AuthProvider>();
    await _chatService.sendMessage(
      senderUid: _myUid,
      senderName: auth.user!.name,
      receiverUid: _otherUid,
      receiverName: _otherName,
      text: text,
    );

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              backgroundImage: widget.worker?.profileImage != null
                  ? profileImageProvider(widget.worker!.profileImage!)
                  : null,
              child: widget.worker?.profileImage == null
                  ? Text(_otherAvatarLetter,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_otherName, style: const TextStyle(fontSize: 15)),
                if (widget.worker != null)
                  Text(
                    widget.worker!.skills.take(2).join(', '),
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.normal),
                  ),
              ],
            ),
          ],
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.chatBackgroundGradient,
        ),
        child: Column(
          children: [
            // ── Messages ──
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream:
                    _chatService.getMessages(uid1: _myUid, uid2: _otherUid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet.\nSay hello! 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final msg = messages[i];
                      final isMe = msg.senderId == _myUid;
                      return _ChatBubble(
                        message: msg,
                        isMe: isMe,
                        otherName: _otherName,
                        workerProfileImage: widget.worker?.profileImage,
                      );
                    },
                  );
                },
              ),
            ),

            // ── Input bar ──
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.92),
                border: const Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: AppStrings.typeMessage,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                const BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                const BorderSide(color: AppColors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      onPressed: _sendMessage,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String otherName;
  final String? workerProfileImage;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.otherName,
    this.workerProfileImage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              backgroundImage: workerProfileImage != null
                  ? profileImageProvider(workerProfileImage!)
                  : null,
              child: workerProfileImage == null
                  ? Text(
                      otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: isMe ? null : Border.all(color: AppColors.divider),
              boxShadow: [
                if (!isMe)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: isMe ? Colors.white : AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}