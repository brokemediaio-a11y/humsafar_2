import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journey_model.dart';
import '../models/booking_request_model.dart';
import '../models/post_model.dart';
import '../models/ride_offer_model.dart';

class JourneyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a journey from an approved booking/post
  Future<String?> createJourney({
    required PostModel post,
    required List<BookingRequestModel> approvedBookings,
  }) async {
    try {
      final journeyId = _firestore.collection('journeys').doc().id;

      // Build passengers list from approved bookings
      final passengers = approvedBookings.map((booking) {
        return PassengerInfo(
          passengerId: booking.passengerId,
          passengerName: booking.passengerName,
          passengerProfileImage: booking.passengerProfileImage,
          seatsBooked: booking.seatsRequested,
        );
      }).toList();

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

      await _firestore.collection('journeys').doc(journeyId).set(journey.toMap());
      return journeyId;
    } catch (e) {
      debugPrint('Error creating journey: $e');
      return null;
    }
  }

  // Get all journeys for a user (as driver or passenger)
  Stream<List<JourneyModel>> getUserJourneys(String userId) {
    final controller = StreamController<List<JourneyModel>>.broadcast();
    final allDocs = <String, JourneyModel>{};
    StreamSubscription? driverSub;
    StreamSubscription? passengerSub;
    bool driverReady = false;
    bool passengerReady = false;
    
    void emitJourneys() {
      if (controller.isClosed) return;
      final journeys = allDocs.values.toList();
      journeys.sort((a, b) {
        if (a.departureTime == null && b.departureTime == null) return 0;
        if (a.departureTime == null) return 1;
        if (b.departureTime == null) return -1;
        return b.departureTime!.compareTo(a.departureTime!);
      });
      controller.add(journeys);
    }
    
    // Emit empty list immediately to prevent infinite loading
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!driverReady && !passengerReady && !controller.isClosed) {
        controller.add([]);
      }
    });
    
    // Get journeys where user is driver
    driverSub = _firestore
        .collection('journeys')
        .where('driverId', isEqualTo: userId)
        .snapshots()
        .listen(
      (snapshot) {
        driverReady = true;
        for (var doc in snapshot.docs) {
          try {
            final journey = JourneyModel.fromMap(doc.data());
            allDocs[journey.id] = journey;
          } catch (e) {
            debugPrint('Error parsing journey: $e');
          }
        }
        emitJourneys();
      },
      onError: (error) {
        debugPrint('Error in driver journeys stream: $error');
        driverReady = true;
        emitJourneys(); // Emit what we have
      },
    );
    
    // Get journeys where user is passenger
    passengerSub = _firestore
        .collection('journeys')
        .where('passengerIds', arrayContains: userId)
        .snapshots()
        .listen(
      (snapshot) {
        passengerReady = true;
        for (var doc in snapshot.docs) {
          try {
            final journey = JourneyModel.fromMap(doc.data());
            allDocs[journey.id] = journey;
          } catch (e) {
            debugPrint('Error parsing journey: $e');
          }
        }
        emitJourneys();
      },
      onError: (error) {
        debugPrint('Error in passenger journeys stream: $error');
        passengerReady = true;
        emitJourneys(); // Emit what we have
      },
    );
    
    controller.onCancel = () {
      driverSub?.cancel();
      passengerSub?.cancel();
    };
    
    return controller.stream;
  }

  // Get active journey for a user (as driver or passenger)
  Stream<JourneyModel?> getActiveJourney(String userId) {
    final controller = StreamController<JourneyModel?>.broadcast();
    JourneyModel? activeJourney;
    StreamSubscription? driverSub;
    StreamSubscription? passengerSub;
    
    void emitActive() {
      if (controller.isClosed) return;
      controller.add(activeJourney);
    }
    
    // Get active journey where user is driver
    driverSub = _firestore
        .collection('journeys')
        .where('driverId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.docs.isNotEmpty) {
          try {
            activeJourney = JourneyModel.fromMap(snapshot.docs.first.data());
          } catch (e) {
            debugPrint('Error parsing active journey: $e');
          }
        } else if (activeJourney == null) {
          // Only set to null if we haven't found one from passenger stream yet
        }
        emitActive();
      },
      onError: (error) {
        debugPrint('Error in driver active journey stream: $error');
        emitActive();
      },
    );
    
    // Get active journey where user is passenger
    passengerSub = _firestore
        .collection('journeys')
        .where('passengerIds', arrayContains: userId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.docs.isNotEmpty && activeJourney == null) {
          try {
            activeJourney = JourneyModel.fromMap(snapshot.docs.first.data());
          } catch (e) {
            debugPrint('Error parsing active journey: $e');
          }
        } else {
          // No active journey found - already null
        }
        emitActive();
      },
      onError: (error) {
        debugPrint('Error in passenger active journey stream: $error');
        if (activeJourney == null) {
          emitActive();
        }
      },
    );
    
    controller.onCancel = () {
      driverSub?.cancel();
      passengerSub?.cancel();
    };
    
    return controller.stream;
  }

  // Start a ride
  Future<bool> startRide(String journeyId) async {
    try {
      final journeyDoc = await _firestore.collection('journeys').doc(journeyId).get();
      if (!journeyDoc.exists) return false;

      final postId = journeyDoc.data()?['postId'] as String?;

      await _firestore.collection('journeys').doc(journeyId).update({
        'status': 'active',
        'startTime': DateTime.now().toIso8601String(),
      });

      if (postId != null && postId.isNotEmpty) {
        try {
          await _firestore.collection('posts').doc(postId).delete();
        } catch (e) {
          debugPrint('Error removing post after ride start: $e');
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error starting ride: $e');
      return false;
    }
  }

  // End a ride
  Future<bool> endRide(String journeyId, int totalEarnings) async {
    try {
      final journeyDoc = await _firestore.collection('journeys').doc(journeyId).get();
      if (!journeyDoc.exists) return false;

      final journey = JourneyModel.fromMap(journeyDoc.data()!);
      
      // Calculate duration
      int? durationMinutes;
      if (journey.startTime != null) {
        durationMinutes = DateTime.now().difference(journey.startTime!).inMinutes;
      }

      await _firestore.collection('journeys').doc(journeyId).update({
        'status': 'completed',
        'endTime': DateTime.now().toIso8601String(),
        'durationMinutes': durationMinutes,
        'totalEarnings': totalEarnings,
      });
      
      debugPrint('✅ Ride ended. Duration: $durationMinutes min, Earnings: Rs. $totalEarnings');
      return true;
    } catch (e) {
      debugPrint('Error ending ride: $e');
      return false;
    }
  }

  // Cancel a journey
  Future<bool> cancelJourney(String journeyId) async {
    try {
      await _firestore.collection('journeys').doc(journeyId).update({
        'status': 'cancelled',
      });
      return true;
    } catch (e) {
      debugPrint('Error cancelling journey: $e');
      return false;
    }
  }

  // Get journey by ID
  Future<JourneyModel?> getJourneyById(String journeyId) async {
    try {
      final doc = await _firestore.collection('journeys').doc(journeyId).get();
      if (!doc.exists) return null;
      return JourneyModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error getting journey: $e');
      return null;
    }
  }

  // Get upcoming journeys (pending) for a user
  Stream<List<JourneyModel>> getUpcomingJourneys(String userId) {
    debugPrint('📍 Getting upcoming journeys for user: $userId');
    final controller = StreamController<List<JourneyModel>>.broadcast();
    final allDocs = <String, JourneyModel>{};
    StreamSubscription? driverSub;
    StreamSubscription? passengerSub;
    
    void emitJourneys() {
      if (controller.isClosed) return;
      final journeys = allDocs.values.toList();
      journeys.sort((a, b) {
        if (a.departureTime == null && b.departureTime == null) return 0;
        if (a.departureTime == null) return 1;
        if (b.departureTime == null) return -1;
        return a.departureTime!.compareTo(b.departureTime!);
      });
      debugPrint('✅ Returning ${journeys.length} upcoming journey(s)');
      controller.add(journeys);
    }
    
    // Get pending journeys where user is driver
    driverSub = _firestore
        .collection('journeys')
        .where('driverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
      (snapshot) {
        for (var doc in snapshot.docs) {
          try {
            final journey = JourneyModel.fromMap(doc.data());
            allDocs[journey.id] = journey;
          } catch (e) {
            debugPrint('Error parsing journey: $e');
          }
        }
        emitJourneys();
      },
      onError: (error) {
        debugPrint('Error in driver upcoming journeys stream: $error');
        emitJourneys();
      },
    );
    
    // Get pending journeys where user is passenger
    passengerSub = _firestore
        .collection('journeys')
        .where('passengerIds', arrayContains: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
      (snapshot) {
        for (var doc in snapshot.docs) {
          try {
            final journey = JourneyModel.fromMap(doc.data());
            allDocs[journey.id] = journey;
          } catch (e) {
            debugPrint('Error parsing journey: $e');
          }
        }
        emitJourneys();
      },
      onError: (error) {
        debugPrint('Error in passenger upcoming journeys stream: $error');
        emitJourneys();
      },
    );
    
    controller.onCancel = () {
      driverSub?.cancel();
      passengerSub?.cancel();
    };
    
    return controller.stream;
  }

  // Get completed journeys for a user
  Stream<List<JourneyModel>> getCompletedJourneys(String userId) {
    final controller = StreamController<List<JourneyModel>>.broadcast();
    final allDocs = <String, JourneyModel>{};
    StreamSubscription? driverSub;
    StreamSubscription? passengerSub;
    
    void emitJourneys() {
      if (controller.isClosed) return;
      final journeys = allDocs.values.toList();
      journeys.sort((a, b) {
        if (a.endTime == null && b.endTime == null) return 0;
        if (a.endTime == null) return 1;
        if (b.endTime == null) return -1;
        return b.endTime!.compareTo(a.endTime!);
      });
      controller.add(journeys);
    }
    
    // Get completed journeys where user is driver
    driverSub = _firestore
        .collection('journeys')
        .where('driverId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen(
      (snapshot) {
        for (var doc in snapshot.docs) {
          try {
            final journey = JourneyModel.fromMap(doc.data());
            allDocs[journey.id] = journey;
          } catch (e) {
            debugPrint('Error parsing journey: $e');
          }
        }
        emitJourneys();
      },
      onError: (error) {
        debugPrint('Error in driver completed journeys stream: $error');
        emitJourneys();
      },
    );
    
    // Get completed journeys where user is passenger
    passengerSub = _firestore
        .collection('journeys')
        .where('passengerIds', arrayContains: userId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen(
      (snapshot) {
        for (var doc in snapshot.docs) {
          try {
            final journey = JourneyModel.fromMap(doc.data());
            allDocs[journey.id] = journey;
          } catch (e) {
            debugPrint('Error parsing journey: $e');
          }
        }
        emitJourneys();
      },
      onError: (error) {
        debugPrint('Error in passenger completed journeys stream: $error');
        emitJourneys();
      },
    );
    
    controller.onCancel = () {
      driverSub?.cancel();
      passengerSub?.cancel();
    };
    
    return controller.stream;
  }
  
  // Create journey from accepted ride offer (for passenger posts)
  Future<String?> createJourneyFromRideOffer({
    required RideOfferModel rideOffer,
  }) async {
    try {
      final journeyId = _firestore.collection('journeys').doc().id;

      // Get passenger name from post
      String passengerName = '';
      String passengerImage = '';
      try {
        final postDoc = await _firestore.collection('posts').doc(rideOffer.postId).get();
        if (postDoc.exists) {
          final postData = postDoc.data() as Map<String, dynamic>;
          passengerName = postData['userName'] ?? '';
          passengerImage = postData['userProfileImageUrl'] ?? '';
        }
      } catch (e) {
        debugPrint('Error getting post data: $e');
      }

      // Create passenger info for the post owner
      final passenger = PassengerInfo(
        passengerId: rideOffer.passengerId,
        passengerName: passengerName,
        passengerProfileImage: passengerImage,
        seatsBooked: rideOffer.seatsNeeded ?? 1,
      );

      final journey = JourneyModel(
        id: journeyId,
        postId: rideOffer.postId,
        driverId: rideOffer.driverId,
        driverName: rideOffer.driverName,
        driverProfileImage: rideOffer.driverProfileImage,
        fromLocation: rideOffer.fromLocation,
        toLocation: rideOffer.toLocation,
        departureTime: rideOffer.departureTime,
        fromLatitude: rideOffer.fromLatitude,
        fromLongitude: rideOffer.fromLongitude,
        toLatitude: rideOffer.toLatitude,
        toLongitude: rideOffer.toLongitude,
        distanceKm: null, // Can be calculated if needed
        carMake: rideOffer.carMake,
        carModel: rideOffer.carModel,
        carColor: rideOffer.carColor,
        carPlate: rideOffer.carPlate,
        status: JourneyStatus.pending,
        passengers: [passenger],
        passengerIds: [rideOffer.passengerId],
        totalSeats: rideOffer.seatsNeeded ?? 1,
        pricePerSeat: rideOffer.ratePerSeat,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('journeys').doc(journeyId).set(journey.toMap());
      debugPrint('✅ Journey created from ride offer: $journeyId');
      return journeyId;
    } catch (e) {
      debugPrint('Error creating journey from ride offer: $e');
      return null;
    }
  }
}

