import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ride_offer_model.dart';
import '../models/alert_model.dart';
import '../services/journey_service.dart';

class RideOfferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _offersCollection =>
      _firestore.collection('ride_offers');
  CollectionReference get _alertsCollection => _firestore.collection('alerts');

  /// Create a new ride offer
  Future<bool> createRideOffer(RideOfferModel offer) async {
    try {
      debugPrint('🚗 Creating ride offer...');
      debugPrint('   Post ID: ${offer.postId}');
      debugPrint('   Passenger ID: ${offer.passengerId}');
      debugPrint('   Driver ID: ${offer.driverId}');
      debugPrint('   Rate: Rs. ${offer.ratePerSeat}');
      
      // Check if driver already has a pending offer for this post
      final existing = await _offersCollection
          .where('postId', isEqualTo: offer.postId)
          .where('driverId', isEqualTo: offer.driverId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existing.docs.isNotEmpty) {
        debugPrint('❌ Driver already has a pending offer for this post');
        return false;
      }

      // Create ride offer
      debugPrint('💾 Saving ride offer to Firestore...');
      await _offersCollection.doc(offer.id).set(offer.toMap());
      debugPrint('✅ Ride offer saved!');

      // Create alert for passenger
      final alert = AlertModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: offer.passengerId,
        type: AlertType.rideOffer,
        title: 'New Ride Offer',
        message: '${offer.driverName} offered a ride for Rs. ${offer.ratePerSeat}/seat',
        relatedId: offer.id,
        createdAt: DateTime.now(),
        metadata: {
          'driverName': offer.driverName,
          'driverImage': offer.driverProfileImage,
          'ratePerSeat': offer.ratePerSeat,
          'carInfo': '${offer.carMake ?? ''} ${offer.carModel ?? ''}'.trim(),
        },
      );
      
      debugPrint('🔔 Creating alert for passenger...');
      debugPrint('   Alert ID: ${alert.id}');
      debugPrint('   Passenger User ID: ${alert.userId}');
      
      await _alertsCollection.doc(alert.id).set(alert.toMap());
      debugPrint('✅ Alert created successfully!');

      return true;
    } catch (e) {
      debugPrint('❌ Error creating ride offer: $e');
      return false;
    }
  }

  /// Accept a ride offer
  Future<bool> acceptRideOffer(String offerId) async {
    try {
      // Update offer status
      final offer = await _offersCollection.doc(offerId).get();
      if (!offer.exists) return false;

      final offerData = RideOfferModel.fromMap(
        offer.data() as Map<String, dynamic>,
      );

      await _offersCollection.doc(offerId).update({
        'status': RideOfferStatus.accepted.name,
        'respondedAt': DateTime.now().toIso8601String(),
      });

      // Create journey from accepted ride offer
      final journeyService = JourneyService();
      await journeyService.createJourneyFromRideOffer(rideOffer: offerData);
      debugPrint('✅ Journey created from accepted ride offer');

      // Create alert for driver
      final alert = AlertModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: offerData.driverId,
        type: AlertType.rideOfferAccepted,
        title: 'Offer Accepted!',
        message: 'Your ride offer has been accepted',
        relatedId: offerId,
        createdAt: DateTime.now(),
      );
      await _alertsCollection.doc(alert.id).set(alert.toMap());

      return true;
    } catch (e) {
      debugPrint('❌ Error accepting ride offer: $e');
      return false;
    }
  }

  /// Decline a ride offer
  Future<bool> declineRideOffer(String offerId) async {
    try {
      // Update offer status
      final offer = await _offersCollection.doc(offerId).get();
      if (!offer.exists) return false;

      final offerData = RideOfferModel.fromMap(
        offer.data() as Map<String, dynamic>,
      );

      await _offersCollection.doc(offerId).update({
        'status': RideOfferStatus.declined.name,
        'respondedAt': DateTime.now().toIso8601String(),
      });

      // Create alert for driver
      final alert = AlertModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: offerData.driverId,
        type: AlertType.rideOfferDeclined,
        title: 'Offer Declined',
        message: 'Your ride offer was declined',
        relatedId: offerId,
        createdAt: DateTime.now(),
      );
      await _alertsCollection.doc(alert.id).set(alert.toMap());

      return true;
    } catch (e) {
      debugPrint('❌ Error declining ride offer: $e');
      return false;
    }
  }

  /// Get ride offer by ID
  Future<RideOfferModel?> getRideOffer(String offerId) async {
    try {
      final doc = await _offersCollection.doc(offerId).get();
      if (doc.exists) {
        return RideOfferModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting ride offer: $e');
      return null;
    }
  }

  /// Get all ride offers for a post (for passenger)
  Stream<List<RideOfferModel>> getPostRideOffers(String postId) {
    debugPrint('📋 Fetching ride offers for post: $postId');
    return _offersCollection
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((snapshot) {
      debugPrint('📋 Got ${snapshot.docs.length} ride offers');
      final offers = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            debugPrint('   - ${data['driverName']} (${data['status']})');
            return RideOfferModel.fromMap(data);
          })
          .toList();
      
      // Sort in memory
      offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return offers;
    });
  }

  /// Get user's ride offers (as driver)
  Stream<List<RideOfferModel>> getUserRideOffers(String userId) {
    return _offersCollection
        .where('driverId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final offers = snapshot.docs
          .map((doc) =>
              RideOfferModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return offers;
    });
  }

  /// Check if driver has pending offer for a post
  Future<bool> hasPendingOffer(String userId, String postId) async {
    try {
      final query = await _offersCollection
          .where('postId', isEqualTo: postId)
          .where('driverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking pending offer: $e');
      return false;
    }
  }
}

