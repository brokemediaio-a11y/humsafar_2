import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../utils/logger.dart';
import 'block_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BlockService _blockService = BlockService();

  CollectionReference get _chatsCollection => _firestore.collection('chats');
  CollectionReference get _messagesCollection =>
      _firestore.collection('messages');

  /// Get or create a chat between two users
  Future<String> getOrCreateChat({
    required String currentUserId,
    required String currentUserName,
    required String currentUserImage,
    required String otherUserId,
    required String otherUserName,
    required String otherUserImage,
  }) async {
    try {
      Logger.debug('Getting or creating chat between $currentUserId and $otherUserId', 'ChatService');

      // Create a consistent chat ID (sorted user IDs)
      final sortedIds = [currentUserId, otherUserId]..sort();
      final chatId = '${sortedIds[0]}_${sortedIds[1]}';

      // Check if chat exists
      final chatDoc = await _chatsCollection.doc(chatId).get();

      if (!chatDoc.exists) {
        // Create new chat
        Logger.debug('Creating new chat: $chatId', 'ChatService');
        final chat = ChatModel(
          id: chatId,
          participantIds: [currentUserId, otherUserId],
          participantNames: {
            currentUserId: currentUserName,
            otherUserId: otherUserName,
          },
          participantImages: {
            currentUserId: currentUserImage,
            otherUserId: otherUserImage,
          },
          unreadCount: {
            currentUserId: 0,
            otherUserId: 0,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _chatsCollection.doc(chatId).set(chat.toMap());
        Logger.info('Chat created successfully', 'ChatService');
      } else {
        Logger.debug('Chat already exists', 'ChatService');
      }

      return chatId;
    } catch (e) {
      Logger.error('Error getting/creating chat', e, null, 'ChatService');
      rethrow;
    }
  }

  /// Send a message
  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    required String receiverId,
  }) async {
    try {
      debugPrint('📤 Sending message...');
      debugPrint('   Chat ID: $chatId');
      debugPrint('   Text: $text');

      // Check if users are blocked
      final areBlocked = await _blockService.areUsersBlocked(
        userId1: senderId,
        userId2: receiverId,
      );

      if (areBlocked) {
        debugPrint('❌ Cannot send message: Users are blocked');
        return false;
      }

      final message = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        text: text,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Save message
      await _messagesCollection.doc(message.id).set(message.toMap());

      // Update chat's last message and unread count
      final chatDoc = await _chatsCollection.doc(chatId).get();
      if (chatDoc.exists) {
        final chat = ChatModel.fromMap(chatDoc.data() as Map<String, dynamic>);
        final newUnreadCount = Map<String, int>.from(chat.unreadCount);
        
        // Increment unread count for receiver
        newUnreadCount[receiverId] = (newUnreadCount[receiverId] ?? 0) + 1;

        await _chatsCollection.doc(chatId).update({
          'lastMessage': text,
          'lastMessageSenderId': senderId,
          'lastMessageTime': message.timestamp.toIso8601String(),
          'unreadCount': newUnreadCount,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('✅ Message sent!');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      return false;
    }
  }

  /// Get messages for a chat
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    debugPrint('📨 Fetching messages for chat: $chatId');
    return _messagesCollection
        .where('chatId', isEqualTo: chatId)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort by timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      debugPrint('   Got ${messages.length} messages');
      return messages;
    });
  }

  /// Get all chats for a user
  Stream<List<ChatModel>> getUserChats(String userId) {
    debugPrint('💬 Fetching chats for user: $userId');
    return _chatsCollection
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort by last message time (most recent first)
      chats.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      debugPrint('   Got ${chats.length} chats');
      return chats;
    });
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      debugPrint('✓ Marking messages as read...');
      
      // Get all unread messages from other user
      final messages = await _messagesCollection
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Mark them as read
      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Reset unread count in chat
      await _chatsCollection.doc(chatId).update({
        'unreadCount.$userId': 0,
      });

      debugPrint('✅ Messages marked as read!');
    } catch (e) {
      debugPrint('❌ Error marking messages as read: $e');
    }
  }

  /// Get total unread messages count for a user
  Stream<int> getTotalUnreadCount(String userId) {
    return _chatsCollection
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final chat = ChatModel.fromMap(doc.data() as Map<String, dynamic>);
        total += chat.getUnreadCount(userId);
      }
      return total;
    });
  }
}

