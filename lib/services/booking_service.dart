import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking_request_model.dart';
import '../models/alert_model.dart';
import '../models/post_model.dart';
import '../models/journey_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _bookingsCollection =>
      _firestore.collection('booking_requests');
  CollectionReference get _alertsCollection => _firestore.collection('alerts');
  CollectionReference get _postsCollection => _firestore.collection('posts');
  CollectionReference get _journeysCollection => _firestore.collection('journeys');

  /// Create a new booking request
  Future<bool> createBookingRequest(BookingRequestModel booking) async {
    try {
      // Check if user already has a pending request for this post
      final existing = await _bookingsCollection
          .where('postId', isEqualTo: booking.postId)
          .where('passengerId', isEqualTo: booking.passengerId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existing.docs.isNotEmpty) {
        return false;
      }

      // Create booking request
      await _bookingsCollection.doc(booking.id).set(booking.toMap());

      // Create alert for driver
      final alert = AlertModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: booking.driverId,
        type: AlertType.bookingRequest,
        title: 'New Booking Request',
        message:
            '${booking.passengerName} requested ${booking.seatsRequested} seat(s)',
        relatedId: booking.id,
        createdAt: DateTime.now(),
        metadata: {
          'passengerName': booking.passengerName,
          'passengerImage': booking.passengerProfileImage,
          'seatsRequested': booking.seatsRequested,
        },
      );
      
      await _alertsCollection.doc(alert.id).set(alert.toMap());

      return true;
    } catch (e) {
      debugPrint('Error creating booking request: $e');
      return false;
    }
  }

  /// Approve a booking request
  Future<bool> approveBookingRequest(
    String bookingId,
    String postId,
    int seatsRequested,
  ) async {
    try {
      // Update booking status
      final booking = await _bookingsCollection.doc(bookingId).get();
      if (!booking.exists) return false;

      final bookingData = BookingRequestModel.fromMap(
        booking.data() as Map<String, dynamic>,
      );

      await _bookingsCollection.doc(bookingId).update({
        'status': BookingStatus.approved.name,
        'respondedAt': DateTime.now().toIso8601String(),
      });

      // Decrease available seats in post
      final postDoc = await _postsCollection.doc(postId).get();
      if (postDoc.exists) {
        final postData = postDoc.data() as Map<String, dynamic>;
        final currentSeats = postData['seatsAvailable'] ?? 0;
        final newSeats = currentSeats - seatsRequested;
        if (newSeats >= 0) {
          await _postsCollection.doc(postId).update({
            'seatsAvailable': newSeats,
          });
        }
      }

      // Create alert for passenger
      final alert = AlertModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: bookingData.passengerId,
        type: AlertType.bookingApproved,
        title: 'Request Approved! 🎉',
        message: 'Your seat request has been approved',
        relatedId: bookingId,
        createdAt: DateTime.now(),
      );
      await _alertsCollection.doc(alert.id).set(alert.toMap());

      // Create or update journey
      await _createOrUpdateJourney(postId, bookingData);

      return true;
    } catch (e) {
      debugPrint('Error approving booking request: $e');
      return false;
    }
  }

  /// Decline a booking request
  Future<bool> declineBookingRequest(String bookingId) async {
    try {
      // Update booking status
      final booking = await _bookingsCollection.doc(bookingId).get();
      if (!booking.exists) return false;

      final bookingData = BookingRequestModel.fromMap(
        booking.data() as Map<String, dynamic>,
      );

      await _bookingsCollection.doc(bookingId).update({
        'status': BookingStatus.declined.name,
        'respondedAt': DateTime.now().toIso8601String(),
      });

      // Create alert for passenger
      final alert = AlertModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: bookingData.passengerId,
        type: AlertType.bookingDeclined,
        title: 'Request Declined',
        message: 'Your seat request was declined',
        relatedId: bookingId,
        createdAt: DateTime.now(),
      );
      await _alertsCollection.doc(alert.id).set(alert.toMap());

      return true;
    } catch (e) {
      debugPrint('Error declining booking request: $e');
      return false;
    }
  }

  /// Get booking request by ID
  Future<BookingRequestModel?> getBookingRequest(String bookingId) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();
      if (doc.exists) {
        return BookingRequestModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting booking request: $e');
      return null;
    }
  }

  /// Get all booking requests for a post (for driver)
  Stream<List<BookingRequestModel>> getPostBookingRequests(String postId) {
    return _bookingsCollection
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return BookingRequestModel.fromMap(data);
          })
          .toList();
      
      // Sort in memory to avoid needing a composite index
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return bookings;
    });
  }

  /// Get user's booking requests (as passenger)
  Stream<List<BookingRequestModel>> getUserBookingRequests(String userId) {
    return _bookingsCollection
        .where('passengerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              BookingRequestModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Get alerts for a user
  Stream<List<AlertModel>> getUserAlerts(String userId) {
    return _alertsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AlertModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Mark alert as read
  Future<bool> markAlertAsRead(String alertId) async {
    try {
      await _alertsCollection.doc(alertId).update({'isRead': true});
      return true;
    } catch (e) {
      debugPrint('Error marking alert as read: $e');
      return false;
    }
  }

  /// Get unread alerts count
  Stream<int> getUnreadAlertsCount(String userId) {
    return _alertsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Check if user has pending request for a post
  Future<bool> hasPendingRequest(String userId, String postId) async {
    try {
      final query = await _bookingsCollection
          .where('postId', isEqualTo: postId)
          .where('passengerId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking pending request: $e');
      return false;
    }
  }

  /// Create or update journey when booking is approved
  Future<void> _createOrUpdateJourney(
    String postId,
    BookingRequestModel approvedBooking,
  ) async {
    try {
      debugPrint('🚗 Creating/updating journey for post: $postId');
      
      // Get the post details
      final postDoc = await _postsCollection.doc(postId).get();
      if (!postDoc.exists) {
        debugPrint('❌ Post not found: $postId');
        return;
      }

      final post = PostModel.fromMap(postDoc.data() as Map<String, dynamic>);
      debugPrint('📝 Post details - Type: ${post.type}, Driver: ${post.userId}, Departure: ${post.departureTime}');

      // Only create journeys for driver posts
      if (post.type != PostType.driver) {
        debugPrint('⚠️ Not a driver post, skipping journey creation');
        return;
      }

      // Check if journey already exists for this post
      final existingJourneys = await _journeysCollection
          .where('postId', isEqualTo: postId)
          .where('status', whereIn: ['pending', 'active']).get();

      debugPrint('🔍 Found ${existingJourneys.docs.length} existing journey(s) for post');

      if (existingJourneys.docs.isEmpty) {
        // Create new journey
        final journeyId = _journeysCollection.doc().id;
        debugPrint('✨ Creating NEW journey with ID: $journeyId');
        final passengers = [
          PassengerInfo(
            passengerId: approvedBooking.passengerId,
            passengerName: approvedBooking.passengerName,
            passengerProfileImage: approvedBooking.passengerProfileImage,
            seatsBooked: approvedBooking.seatsRequested,
          ),
        ];

        final passengerIds = passengers.map((p) => p.passengerId).toList();
        
        final journey = JourneyModel(
          id: journeyId,
          postId: post.id,
          driverId: post.userId,
          driverName: post.userName,
          driverProfileImage: post.userProfileImageUrl,
          fromLocation: post.fromLocation,
          toLocation: post.toLocation,
          departureTime: post.departureTime,
          fromLatitude: post.fromLatitude,
          fromLongitude: post.fromLongitude,
          toLatitude: post.toLatitude,
          toLongitude: post.toLongitude,
          distanceKm: post.distanceKm,
          carMake: post.carMake,
          carModel: post.carModel,
          carColor: post.carColor,
          carPlate: post.carPlate,
          status: JourneyStatus.pending,
          passengers: passengers,
          passengerIds: passengerIds,
          totalSeats: post.seatsAvailable ?? 0,
          pricePerSeat: post.price ?? 0,
          createdAt: DateTime.now(),
        );

        await _journeysCollection.doc(journeyId).set(journey.toMap());
        debugPrint('✅ Journey created successfully with ${journey.passengers.length} passenger(s)');
      } else {
        // Update existing journey with new passenger
        final journeyDoc = existingJourneys.docs.first;
        final journey = JourneyModel.fromMap(journeyDoc.data() as Map<String, dynamic>);
        debugPrint('📝 Updating existing journey: ${journey.id}');

        // Check if passenger already exists
        final passengerExists = journey.passengers
            .any((p) => p.passengerId == approvedBooking.passengerId);

        if (!passengerExists) {
          final updatedPassengers = [
            ...journey.passengers,
            PassengerInfo(
              passengerId: approvedBooking.passengerId,
              passengerName: approvedBooking.passengerName,
              passengerProfileImage: approvedBooking.passengerProfileImage,
              seatsBooked: approvedBooking.seatsRequested,
            ),
          ];
          
          final updatedPassengerIds = [
            ...journey.passengerIds,
            approvedBooking.passengerId,
          ];

          await _journeysCollection.doc(journey.id).update({
            'passengers': updatedPassengers.map((p) => p.toMap()).toList(),
            'passengerIds': updatedPassengerIds,
          });
          debugPrint('✅ Journey updated with new passenger. Total: ${updatedPassengers.length}');
        } else {
          debugPrint('⚠️ Passenger already exists in journey');
        }
      }
    } catch (e) {
      debugPrint('❌ Error creating/updating journey: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }
}

