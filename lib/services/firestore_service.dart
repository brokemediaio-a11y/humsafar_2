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
}

