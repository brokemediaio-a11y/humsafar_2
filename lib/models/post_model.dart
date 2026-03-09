enum PostType { driver, passenger }

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String userProfileImageUrl;
  final bool isVerified;
  final PostType type; // driver or passenger
  final String fromLocation;
  final String toLocation;
  final DateTime? departureTime;
  final String? timeWindow; // For passengers
  final int? seatsAvailable; // For drivers
  final int? seatsNeeded; // For passengers
  final int? price; // For drivers
  final String? carMake; // For drivers
  final String? carModel; // For drivers
  final String? carColor; // For drivers
  final String? carPlate; // For drivers
  final double? fromLatitude; // For map
  final double? fromLongitude; // For map
  final double? toLatitude; // For map
  final double? toLongitude; // For map
  final double? distanceKm; // Calculated distance
  final String? notes; // Optional notes
  final List<String>? tags; // e.g., "Female-only", "Music on", "AC available"
  final int? etaMinutes; // For drivers
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userProfileImageUrl,
    required this.isVerified,
    required this.type,
    required this.fromLocation,
    required this.toLocation,
    this.departureTime,
    this.timeWindow,
    this.seatsAvailable,
    this.seatsNeeded,
    this.price,
    this.carMake,
    this.carModel,
    this.carColor,
    this.carPlate,
    this.fromLatitude,
    this.fromLongitude,
    this.toLatitude,
    this.toLongitude,
    this.distanceKm,
    this.notes,
    this.tags,
    this.etaMinutes,
    required this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userProfileImageUrl': userProfileImageUrl,
      'isVerified': isVerified,
      'type': type == PostType.driver ? 'driver' : 'passenger',
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'departureTime': departureTime?.toIso8601String(),
      'timeWindow': timeWindow,
      'seatsAvailable': seatsAvailable,
      'seatsNeeded': seatsNeeded,
      'price': price,
      'carMake': carMake,
      'carModel': carModel,
      'carColor': carColor,
      'carPlate': carPlate,
      'fromLatitude': fromLatitude,
      'fromLongitude': fromLongitude,
      'toLatitude': toLatitude,
      'toLongitude': toLongitude,
      'distanceKm': distanceKm,
      'notes': notes,
      'tags': tags,
      'etaMinutes': etaMinutes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userProfileImageUrl: map['userProfileImageUrl'] ?? '',
      isVerified: map['isVerified'] ?? false,
      type: map['type'] == 'driver' ? PostType.driver : PostType.passenger,
      fromLocation: map['fromLocation'] ?? '',
      toLocation: map['toLocation'] ?? '',
      departureTime: map['departureTime'] != null
          ? DateTime.parse(map['departureTime'])
          : null,
      timeWindow: map['timeWindow'],
      seatsAvailable: map['seatsAvailable'],
      seatsNeeded: map['seatsNeeded'],
      price: map['price'],
      carMake: map['carMake'],
      carModel: map['carModel'],
      carColor: map['carColor'],
      carPlate: map['carPlate'],
      fromLatitude: map['fromLatitude']?.toDouble(),
      fromLongitude: map['fromLongitude']?.toDouble(),
      toLatitude: map['toLatitude']?.toDouble(),
      toLongitude: map['toLongitude']?.toDouble(),
      distanceKm: map['distanceKm']?.toDouble(),
      notes: map['notes'],
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      etaMinutes: map['etaMinutes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

