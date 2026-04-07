import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/block_model.dart';

class BlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Block a user
  Future<bool> blockUser({
    required String blockerId,
    required String blockedUserId,
    required String blockerName,
    required String blockedUserName,
    String? reason,
  }) async {
    try {
      final blockId = '${blockerId}_blocks_$blockedUserId';
      
      final block = BlockModel(
        id: blockId,
        blockerId: blockerId,
        blockedUserId: blockedUserId,
        blockerName: blockerName,
        blockedUserName: blockedUserName,
        createdAt: DateTime.now(),
        reason: reason,
      );

      await _firestore
          .collection('blocks')
          .doc(blockId)
          .set(block.toMap());
      
      return true;
    } catch (e) {
      debugPrint('Error blocking user: $e');
      return false;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    try {
      final blockId = '${blockerId}_blocks_$blockedUserId';
      
      await _firestore
          .collection('blocks')
          .doc(blockId)
          .delete();
      
      return true;
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      return false;
    }
  }

  /// Check if user A has blocked user B
  Future<bool> isUserBlocked({
    required String blockerId,
    required String blockedUserId,
  }) async {
    try {
      final blockId = '${blockerId}_blocks_$blockedUserId';
      
      final doc = await _firestore
          .collection('blocks')
          .doc(blockId)
          .get();
      
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
      return false;
    }
  }

  /// Check if two users have blocked each other (either direction)
  Future<bool> areUsersBlocked({
    required String userId1,
    required String userId2,
  }) async {
    try {
      final block1 = await isUserBlocked(
        blockerId: userId1,
        blockedUserId: userId2,
      );
      
      final block2 = await isUserBlocked(
        blockerId: userId2,
        blockedUserId: userId1,
      );
      
      return block1 || block2;
    } catch (e) {
      debugPrint('Error checking if users are blocked: $e');
      return false;
    }
  }

  /// Get users blocked by a specific user
  Future<List<BlockModel>> getBlockedUsers(String blockerId) async {
    try {
      final snapshot = await _firestore
          .collection('blocks')
          .where('blockerId', isEqualTo: blockerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BlockModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting blocked users: $e');
      return [];
    }
  }

  /// Get users who have blocked a specific user
  Future<List<BlockModel>> getUsersWhoBlockedMe(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('blocks')
          .where('blockedUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BlockModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting users who blocked me: $e');
      return [];
    }
  }

  /// Stream to listen for block status changes
  Stream<bool> isUserBlockedStream({
    required String blockerId,
    required String blockedUserId,
  }) {
    final blockId = '${blockerId}_blocks_$blockedUserId';
    
    return _firestore
        .collection('blocks')
        .doc(blockId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Stream to listen for mutual block status changes
  Stream<bool> areUsersBlockedStream({
    required String userId1,
    required String userId2,
  }) {
    return _firestore
        .collection('blocks')
        .where('blockerId', whereIn: [userId1, userId2])
        .where('blockedUserId', whereIn: [userId1, userId2])
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }
}