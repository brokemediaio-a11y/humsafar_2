import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/user_search_service.dart';
import '../services/firestore_service.dart';
import '../services/block_service.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final UserSearchService _userSearchService = UserSearchService();
  final FirestoreService _firestoreService = FirestoreService();
  final BlockService _blockService = BlockService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isSearching = false;
  List<UserModel> _searchResults = [];
  bool _isLoadingSearch = false;

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      }
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openChat(ChatModel chat) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final otherUserId = chat.getOtherUserId(currentUser.uid);
    
    // Check if users are blocked before opening chat
    final areBlocked = await _blockService.areUsersBlocked(
      userId1: currentUser.uid,
      userId2: otherUserId,
    );

    if (areBlocked && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot open chat with blocked user'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chatId: chat.id,
            otherUserId: otherUserId,
            otherUserName: chat.getOtherUserName(currentUser.uid),
            otherUserImage: chat.getOtherUserImage(currentUser.uid),
          ),
        ),
      );
    }
  }

  Future<void> _startChatWithUser(UserModel user) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    // Check if users are blocked
    final areBlocked = await _blockService.areUsersBlocked(
      userId1: currentUser.uid,
      userId2: user.uid,
    );

    if (areBlocked && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot start chat with blocked user'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get current user data
    final currentUserData = await _firestoreService.getUser(currentUser.uid);
    if (currentUserData == null || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF49977a)),
      ),
    );

    try {
      // Get or create chat
      final chatId = await _chatService.getOrCreateChat(
        currentUserId: currentUser.uid,
        currentUserName: currentUserData.fullName,
        currentUserImage: currentUserData.profileImageUrl ?? '',
        otherUserId: user.uid,
        otherUserName: user.fullName,
        otherUserImage: user.profileImageUrl ?? '',
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Navigate to chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chatId: chatId,
            otherUserId: user.uid,
            otherUserName: user.fullName,
            otherUserImage: user.profileImageUrl ?? '',
          ),
        ),
      );

      // Clear search
      _searchController.clear();
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start chat'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoadingSearch = true;
    });

    final currentUser = _authService.currentUser;
    final results = await _userSearchService.searchUsers(
      query,
      excludeUserId: currentUser?.uid,
    );

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoadingSearch = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view chats')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users to message...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF49977a)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF49977a), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _searchUsers,
            ),
          ),
          
          // Content
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildChatsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoadingSearch) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF49977a)),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching by name, email, or student ID',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 72,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade300,
            child: user.profileImageUrl?.isNotEmpty == true
                ? ClipOval(
                    child: Image.network(
                      user.profileImageUrl!,
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          color: Colors.grey.shade600,
                          size: 24,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: Colors.grey.shade600,
                    size: 24,
                  ),
          ),
          title: Text(
            user.fullName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.email,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              if (user.studentId.isNotEmpty)
                Text(
                  'ID: ${user.studentId}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF49977a)),
            onPressed: () => _startChatWithUser(user),
            tooltip: 'Start chat',
          ),
          onTap: () => _startChatWithUser(user),
        );
      },
    );
  }

  Widget _buildChatsList() {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Please login to view chats'));
    }

    return StreamBuilder<List<ChatModel>>(
        stream: _chatService.getUserChats(currentUser.uid),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final chats = (snapshot.data ?? [])
              .where((chat) {
                // Filter out invalid chats
                if (chat.participantIds.length < 2) return false;
                if (!chat.participantIds.contains(currentUser.uid)) return false;
                return true;
              })
              .toList();

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation by messaging someone',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 88,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final unreadCount = chat.getUnreadCount(currentUser.uid);
              final isUnread = unreadCount > 0;
              final otherUserName = chat.getOtherUserName(currentUser.uid);
              final otherUserImage = chat.getOtherUserImage(currentUser.uid);

              return InkWell(
                onTap: () => _openChat(chat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: isUnread
                      ? const Color(0xFF49977a).withValues(alpha: 0.05)
                      : Colors.white,
                  child: Row(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey.shade300,
                            child: otherUserImage.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      otherUserImage,
                                      fit: BoxFit.cover,
                                      width: 56,
                                      height: 56,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.person,
                                          color: Colors.grey.shade600,
                                          size: 28,
                                        );
                                      },
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    color: Colors.grey.shade600,
                                    size: 28,
                                  ),
                          ),
                          if (isUnread)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF49977a),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Chat Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    otherUserName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isUnread
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: const Color(0xFF1F2937),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (chat.lastMessageTime != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTime(chat.lastMessageTime!),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isUnread
                                          ? const Color(0xFF49977a)
                                          : Colors.grey.shade500,
                                      fontWeight: isUnread
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    chat.lastMessage ?? 'No messages yet',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isUnread
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade600,
                                      fontWeight: isUnread
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (unreadCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF49977a),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
  }
}

