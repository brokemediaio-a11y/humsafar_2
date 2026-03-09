import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search users by name, email, or student ID
  // If query is empty, returns all users (useful for @ mentions)
  Future<List<UserModel>> searchUsers(String query, {String? excludeUserId}) async {
    try {
      // Get all users (we'll filter client-side for better search experience)
      final snapshot = await _firestore
          .collection('users')
          .limit(50) // Limit to prevent excessive data transfer
          .get();

      final allUsers = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where((user) {
            // Exclude current user if specified
            if (excludeUserId != null && user.uid == excludeUserId) {
              return false;
            }
            return true;
          })
          .toList();

      // If query is empty, return all users
      if (query.trim().isEmpty) {
        allUsers.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
        return allUsers;
      }

      // Filter by query
      final lowercaseQuery = query.toLowerCase().trim();
      final users = allUsers.where((user) {
        // Search in multiple fields
        final fullName = user.fullName.toLowerCase();
        final email = user.email.toLowerCase();
        final studentId = user.studentId.toLowerCase();

        return fullName.contains(lowercaseQuery) ||
               email.contains(lowercaseQuery) ||
               studentId.contains(lowercaseQuery);
      }).toList();

      // Sort by relevance (exact matches first, then partial matches)
      users.sort((a, b) {
        final aFullName = a.fullName.toLowerCase();
        final bFullName = b.fullName.toLowerCase();
        
        // Exact matches first
        if (aFullName == lowercaseQuery && bFullName != lowercaseQuery) return -1;
        if (bFullName == lowercaseQuery && aFullName != lowercaseQuery) return 1;
        
        // Then starts with query
        if (aFullName.startsWith(lowercaseQuery) && !bFullName.startsWith(lowercaseQuery)) return -1;
        if (bFullName.startsWith(lowercaseQuery) && !aFullName.startsWith(lowercaseQuery)) return 1;
        
        // Finally alphabetical
        return aFullName.compareTo(bFullName);
      });

      return users;
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Get user by ID for chat creation
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }
}
