import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _usersCollection =>
      _firestore.collection('users');

  /// Get user profile by ID
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(String userId, UserModel user) async {
    try {
      await _usersCollection.doc(userId).set(user.toMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }

  /// Create user profile
  Future<bool> createUserProfile(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toMap());
      return true;
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      return false;
    }
  }

  /// Check if user profile exists
  Future<bool> userProfileExists(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking user profile: $e');
      return false;
    }
  }

  /// Get user's total earnings
  Future<double> getUserTotalEarnings(String userId) async {
    try {
      final journeysQuery = await _firestore
          .collection('journeys')
          .where('driverId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      double totalEarnings = 0.0;
      for (final doc in journeysQuery.docs) {
        final data = doc.data();
        final earnings = data['totalEarnings'] as double?;
        if (earnings != null) {
          totalEarnings += earnings;
        }
      }

      return totalEarnings;
    } catch (e) {
      debugPrint('Error getting user total earnings: $e');
      return 0.0;
    }
  }

  /// Get user profile stream for real-time updates
  Stream<UserModel?> getUserProfileStream(String userId) {
    return _usersCollection
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
          }
          return null;
        });
  }

  /// Get user's ride statistics
  Future<Map<String, int>> getUserRideStats(String userId) async {
    try {
      // Get rides as driver
      final driverJourneysQuery = await _firestore
          .collection('journeys')
          .where('driverId', isEqualTo: userId)
          .get();

      // Get rides as passenger
      final passengerJourneysQuery = await _firestore
          .collection('journeys')
          .where('passengerIds', arrayContains: userId)
          .get();

      int totalRidesAsDriver = 0;
      int completedRidesAsDriver = 0;
      int totalPassengersCarried = 0;

      for (final doc in driverJourneysQuery.docs) {
        final data = doc.data();
        totalRidesAsDriver++;
        
        if (data['status'] == 'completed') {
          completedRidesAsDriver++;
          final passengers = data['passengers'] as List?;
          if (passengers != null) {
            totalPassengersCarried += passengers.length;
          }
        }
      }

      final totalRidesAsPassenger = passengerJourneysQuery.docs.length;

      return {
        'totalRidesAsDriver': totalRidesAsDriver,
        'completedRidesAsDriver': completedRidesAsDriver,
        'totalRidesAsPassenger': totalRidesAsPassenger,
        'totalPassengersCarried': totalPassengersCarried,
      };
    } catch (e) {
      debugPrint('Error getting user ride stats: $e');
      return {
        'totalRidesAsDriver': 0,
        'completedRidesAsDriver': 0,
        'totalRidesAsPassenger': 0,
        'totalPassengersCarried': 0,
      };
    }
  }
}
