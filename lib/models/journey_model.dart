enum JourneyStatus { pending, active, completed, cancelled }

class JourneyModel {
  final String id;
  final String postId;
  final String driverId;
  final String driverName;
  final String driverProfileImage;
  
  // Trip details
  final String fromLocation;
  final String toLocation;
  final DateTime? departureTime;
  final double? fromLatitude;
  final double? fromLongitude;
  final double? toLatitude;
  final double? toLongitude;
  final double? distanceKm;
  
  // Car details
  final String? carMake;
  final String? carModel;
  final String? carColor;
  final String? carPlate;
  
  // Journey status
  final JourneyStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes; // Total ride duration
  
  // Passengers
  final List<PassengerInfo> passengers;
  final List<String> passengerIds; // List of passenger user IDs for querying
  final int totalSeats;
  final int pricePerSeat;
  final int? totalEarnings; // Total amount earned from the ride
  
  final DateTime createdAt;

  JourneyModel({
    required this.id,
    required this.postId,
    required this.driverId,
    required this.driverName,
    required this.driverProfileImage,
    required this.fromLocation,
    required this.toLocation,
    this.departureTime,
    this.fromLatitude,
    this.fromLongitude,
    this.toLatitude,
    this.toLongitude,
    this.distanceKm,
    this.carMake,
    this.carModel,
    this.carColor,
    this.carPlate,
    required this.status,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    required this.passengers,
    required this.passengerIds,
    required this.totalSeats,
    required this.pricePerSeat,
    this.totalEarnings,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'driverId': driverId,
      'driverName': driverName,
      'driverProfileImage': driverProfileImage,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'departureTime': departureTime?.toIso8601String(),
      'fromLatitude': fromLatitude,
      'fromLongitude': fromLongitude,
      'toLatitude': toLatitude,
      'toLongitude': toLongitude,
      'distanceKm': distanceKm,
      'carMake': carMake,
      'carModel': carModel,
      'carColor': carColor,
      'carPlate': carPlate,
      'status': status.name,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'passengers': passengers.map((p) => p.toMap()).toList(),
      'passengerIds': passengerIds,
      'totalSeats': totalSeats,
      'pricePerSeat': pricePerSeat,
      'totalEarnings': totalEarnings,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory JourneyModel.fromMap(Map<String, dynamic> map) {
    return JourneyModel(
      id: map['id'] ?? '',
      postId: map['postId'] ?? '',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      driverProfileImage: map['driverProfileImage'] ?? '',
      fromLocation: map['fromLocation'] ?? '',
      toLocation: map['toLocation'] ?? '',
      departureTime: map['departureTime'] != null
          ? DateTime.parse(map['departureTime'])
          : null,
      fromLatitude: map['fromLatitude']?.toDouble(),
      fromLongitude: map['fromLongitude']?.toDouble(),
      toLatitude: map['toLatitude']?.toDouble(),
      toLongitude: map['toLongitude']?.toDouble(),
      distanceKm: map['distanceKm']?.toDouble(),
      carMake: map['carMake'],
      carModel: map['carModel'],
      carColor: map['carColor'],
      carPlate: map['carPlate'],
      status: JourneyStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => JourneyStatus.pending,
      ),
      startTime:
          map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      durationMinutes: map['durationMinutes'],
      passengers: map['passengers'] != null
          ? (map['passengers'] as List)
              .map((p) => PassengerInfo.fromMap(p))
              .toList()
          : [],
      passengerIds: map['passengerIds'] != null
          ? List<String>.from(map['passengerIds'])
          : [],
      totalSeats: map['totalSeats'] ?? 0,
      pricePerSeat: map['pricePerSeat'] ?? 0,
      totalEarnings: map['totalEarnings'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  JourneyModel copyWith({
    JourneyStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    int? totalEarnings,
  }) {
    return JourneyModel(
      id: id,
      postId: postId,
      driverId: driverId,
      driverName: driverName,
      driverProfileImage: driverProfileImage,
      fromLocation: fromLocation,
      toLocation: toLocation,
      departureTime: departureTime,
      fromLatitude: fromLatitude,
      fromLongitude: fromLongitude,
      toLatitude: toLatitude,
      toLongitude: toLongitude,
      distanceKm: distanceKm,
      carMake: carMake,
      carModel: carModel,
      carColor: carColor,
      carPlate: carPlate,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      passengers: passengers,
      passengerIds: passengerIds,
      totalSeats: totalSeats,
      pricePerSeat: pricePerSeat,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      createdAt: createdAt,
    );
  }
  
  // Check if user is the driver
  bool isDriver(String userId) {
    return driverId == userId;
  }
  
  // Check if user is a passenger
  bool isPassenger(String userId) {
    return passengerIds.contains(userId);
  }
  
  // Calculate total earnings from all passengers
  int calculateEarnings() {
    int total = 0;
    for (var passenger in passengers) {
      total += passenger.seatsBooked * pricePerSeat;
    }
    return total;
  }

  // Check if ride can be started (only after departure time)
  bool canStart() {
    if (status != JourneyStatus.pending || departureTime == null) {
      return false;
    }
    return DateTime.now().isAfter(departureTime!.subtract(const Duration(minutes: 5)));
  }

  // Check if ride is currently active
  bool isActive() {
    return status == JourneyStatus.active;
  }
}

class PassengerInfo {
  final String passengerId;
  final String passengerName;
  final String passengerProfileImage;
  final int seatsBooked;

  PassengerInfo({
    required this.passengerId,
    required this.passengerName,
    required this.passengerProfileImage,
    required this.seatsBooked,
  });

  Map<String, dynamic> toMap() {
    return {
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerProfileImage': passengerProfileImage,
      'seatsBooked': seatsBooked,
    };
  }

  factory PassengerInfo.fromMap(Map<String, dynamic> map) {
    return PassengerInfo(
      passengerId: map['passengerId'] ?? '',
      passengerName: map['passengerName'] ?? '',
      passengerProfileImage: map['passengerProfileImage'] ?? '',
      seatsBooked: map['seatsBooked'] ?? 0,
    );
  }
}

