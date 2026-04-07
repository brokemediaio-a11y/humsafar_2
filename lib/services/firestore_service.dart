import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection =>
      _firestore.collection('users');

  /// Save user data to Firestore
  /// Collections are created automatically when you write data
  Future<bool> saveUser(UserModel user) async {
    try {
      // Add timeout to prevent infinite retries
      await _usersCollection.doc(user.uid).set(user.toMap()).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Firestore operation timed out');
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error saving user: $e');
      // Check if it's a database not found error
      final errorStr = e.toString();
      if (errorStr.contains('NOT_FOUND') || errorStr.contains('does not exist')) {
        debugPrint('Firestore database does not exist. Please create it in Firebase Console.');
      }
      return false;
    }
  }

  /// Get user data from Firestore
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Update user data
  Future<bool> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await _usersCollection.doc(uid).update(updates);
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  /// Check if student ID already exists
  Future<bool> studentIdExists(String studentId) async {
    try {
      final query = await _usersCollection
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking student ID: $e');
      return false;
    }
  }

  /// Check if CNIC already exists
  Future<bool> cnicExists(String cnic) async {
    try {
      final query = await _usersCollection
          .where('cnic', isEqualTo: cnic)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking CNIC: $e');
      return false;
    }
  }

  /// Delete user account data from Firestore collections.
  Future<bool> deleteUserAccountData(String uid) async {
    try {
      // Primary profile
      await _usersCollection.doc(uid).delete();

      // User-owned/related documents
      await _deleteByField('posts', 'userId', uid);
      await _deleteByField('booking_requests', 'passengerId', uid);
      await _deleteByField('booking_requests', 'driverId', uid);
      await _deleteByField('ride_offers', 'passengerId', uid);
      await _deleteByField('ride_offers', 'driverId', uid);
      await _deleteByField('alerts', 'userId', uid);
      await _deleteByField('ratings', 'raterId', uid);
      await _deleteByField('ratings', 'ratedUserId', uid);
      await _deleteByField('reports', 'reporterId', uid);
      await _deleteByField('reports', 'reportedUserId', uid);
      await _deleteByField('blocks', 'blockerId', uid);
      await _deleteByField('blocks', 'blockedUserId', uid);
      await _deleteByField('messages', 'senderId', uid);
      await _deleteByArrayContains('journeys', 'passengerIds', uid);
      await _deleteByField('journeys', 'driverId', uid);

      // Delete chats and their messages for this user.
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participantIds', arrayContains: uid)
          .get();
      for (final chatDoc in chatsSnapshot.docs) {
        final chatId = chatDoc.id;
        await _deleteByField('messages', 'chatId', chatId);
        await chatDoc.reference.delete();
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting user account data: $e');
      return false;
    }
  }

  Future<void> _deleteByField(
    String collection,
    String field,
    String value,
  ) async {
    final querySnapshot = await _firestore
        .collection(collection)
        .where(field, isEqualTo: value)
        .get();
    await _deleteQuerySnapshot(querySnapshot);
  }

  Future<void> _deleteByArrayContains(
    String collection,
    String field,
    String value,
  ) async {
    final querySnapshot = await _firestore
        .collection(collection)
        .where(field, arrayContains: value)
        .get();
    await _deleteQuerySnapshot(querySnapshot);
  }

  Future<void> _deleteQuerySnapshot(
    QuerySnapshot<Map<String, dynamic>> querySnapshot,
  ) async {
    if (querySnapshot.docs.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    int count = 0;
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
      count++;
      if (count == 400) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }
}

