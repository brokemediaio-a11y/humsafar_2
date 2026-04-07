import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/block_service.dart';
import '../widgets/block_dialog.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserImage;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserImage,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final BlockService _blockService = BlockService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isBlocked = false;
  bool _isCheckingBlockStatus = true;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _checkBlockStatus();
  }

  void _checkBlockStatus() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final blocked = await _blockService.areUsersBlocked(
        userId1: currentUser.uid,
        userId2: widget.otherUserId,
      );
      if (mounted) {
        setState(() {
          _isBlocked = blocked;
          _isCheckingBlockStatus = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markMessagesAsRead() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      await _chatService.markMessagesAsRead(widget.chatId, currentUser.uid);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    // Check if users are blocked
    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot send message. User is blocked.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    final success = await _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: currentUser.uid,
      senderName: currentUser.displayName ?? 'User',
      text: text,
      receiverId: widget.otherUserId,
    );

    if (mounted) {
      setState(() => _isSending = false);
    }

    if (success) {
      _messageController.clear();
      _scrollToBottom();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      return DateFormat('h:mm a').format(time);
    }
    return DateFormat('MMM d, h:mm a').format(time);
  }

  Future<void> _handleBlockUser() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    await showBlockDialog(
      context: context,
      currentUserId: currentUser.uid,
      currentUserName: currentUser.displayName ?? 'User',
      otherUserId: widget.otherUserId,
      otherUserName: widget.otherUserName,
      onUserBlocked: () {
        setState(() => _isBlocked = true);
      },
    );
  }

  Future<void> _handleUnblockUser() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock ${widget.otherUserName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF49977a),
            ),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _blockService.unblockUser(
        blockerId: currentUser.uid,
        blockedUserId: widget.otherUserId,
      );

      if (mounted) {
        if (success) {
          setState(() => _isBlocked = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.otherUserName} has been unblocked'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to unblock user. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              child: widget.otherUserImage.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        widget.otherUserImage,
                        fit: BoxFit.cover,
                        width: 36,
                        height: 36,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            color: Colors.grey.shade600,
                            size: 20,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isCheckingBlockStatus)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1F2937)),
              onSelected: (value) {
                switch (value) {
                  case 'block':
                    _handleBlockUser();
                    break;
                  case 'unblock':
                    _handleUnblockUser();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: _isBlocked ? 'unblock' : 'block',
                  child: Row(
                    children: [
                      Icon(
                        _isBlocked ? Icons.check_circle : Icons.block,
                        size: 20,
                        color: _isBlocked ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(_isBlocked ? 'Unblock User' : 'Block User'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF49977a),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.uid;
                    final showTimestamp = index == 0 ||
                        messages[index - 1]
                                .timestamp
                                .difference(message.timestamp)
                                .abs()
                                .inMinutes >
                            5;

                    return Column(
                      children: [
                        if (showTimestamp)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              _formatMessageTime(message.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        _buildMessageBubble(message, isMe),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: _isBlocked
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.block,
                            color: Colors.red.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You cannot send messages to this user',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  hintStyle: TextStyle(color: Colors.grey.shade500),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                maxLines: null,
                                textCapitalization: TextCapitalization.sentences,
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF49977a),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.send, color: Colors.white),
                              onPressed: _isSending ? null : _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF49977a)
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 15,
            color: isMe ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }
}

