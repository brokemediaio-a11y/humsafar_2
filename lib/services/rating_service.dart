import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/rating_model.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit a rating
  Future<bool> submitRating(RatingModel rating) async {
    try {
      await _firestore
          .collection('ratings')
          .doc(rating.id)
          .set(rating.toMap());
      
      // Update user's average rating
      await _updateUserAverageRating(rating.ratedUserId);
      
      return true;
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      return false;
    }
  }

  // Get ratings for a specific journey
  Future<List<RatingModel>> getJourneyRatings(String journeyId) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('journeyId', isEqualTo: journeyId)
          .get();

      return snapshot.docs
          .map((doc) => RatingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting journey ratings: $e');
      return [];
    }
  }

  // Check if user has already rated someone for a specific journey
  Future<bool> hasUserRated({
    required String journeyId,
    required String raterId,
    required String ratedUserId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('journeyId', isEqualTo: journeyId)
          .where('raterId', isEqualTo: raterId)
          .where('ratedUserId', isEqualTo: ratedUserId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user has rated: $e');
      return false;
    }
  }

  // Get ratings given by a user
  Future<List<RatingModel>> getRatingsGivenByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('raterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RatingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting ratings given by user: $e');
      return [];
    }
  }

  // Get ratings received by a user
  Future<List<RatingModel>> getRatingsReceivedByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('ratedUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RatingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting ratings received by user: $e');
      return [];
    }
  }

  // Update user's average rating in their profile
  Future<void> _updateUserAverageRating(String userId) async {
    try {
      final ratings = await getRatingsReceivedByUser(userId);
      
      if (ratings.isEmpty) return;

      final averageRating = ratings
          .map((r) => r.rating)
          .reduce((a, b) => a + b) / ratings.length;

      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'rating': averageRating,
            'totalRatings': ratings.length,
          });
    } catch (e) {
      debugPrint('Error updating user average rating: $e');
    }
  }

  // Get pending ratings for a user (journeys they need to rate)
  Future<List<Map<String, dynamic>>> getPendingRatings(String userId) async {
    try {
      // Get completed journeys where user was involved
      final journeysSnapshot = await _firestore
          .collection('journeys')
          .where('status', isEqualTo: 'completed')
          .get();

      List<Map<String, dynamic>> pendingRatings = [];

      for (var journeyDoc in journeysSnapshot.docs) {
        final journeyData = journeyDoc.data();
        final journeyId = journeyDoc.id;
        final driverId = journeyData['driverId'];
        final passengers = List<Map<String, dynamic>>.from(journeyData['passengers'] ?? []);

        // Check if user was the driver
        if (driverId == userId) {
          // Driver needs to rate passengers
          for (var passenger in passengers) {
            final passengerId = passenger['userId'];
            final hasRated = await hasUserRated(
              journeyId: journeyId,
              raterId: userId,
              ratedUserId: passengerId,
            );

            if (!hasRated) {
              pendingRatings.add({
                'journeyId': journeyId,
                'userToRate': passenger,
                'type': RatingType.driver_to_passenger,
                'journeyData': journeyData,
              });
            }
          }
        }

        // Check if user was a passenger
        final userAsPassenger = passengers.firstWhere(
          (p) => p['userId'] == userId,
          orElse: () => {},
        );

        if (userAsPassenger.isNotEmpty) {
          // Passenger needs to rate driver
          final hasRated = await hasUserRated(
            journeyId: journeyId,
            raterId: userId,
            ratedUserId: driverId,
          );

          if (!hasRated) {
            pendingRatings.add({
              'journeyId': journeyId,
              'userToRate': {'userId': driverId, 'name': journeyData['driverName']},
              'type': RatingType.passenger_to_driver,
              'journeyData': journeyData,
            });
          }
        }
      }

      return pendingRatings;
    } catch (e) {
      debugPrint('Error getting pending ratings: $e');
      return [];
    }
  }
}
