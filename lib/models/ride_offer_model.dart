enum RideOfferStatus { pending, accepted, declined, cancelled }

class RideOfferModel {
  final String id;
  final String postId; // The passenger post ID
  final String passengerId; // Post owner's user ID (person who needs ride)
  final String driverId; // Person offering the ride
  final String driverName;
  final String driverProfileImage;
  
  // Car details
  final String? carMake;
  final String? carModel;
  final String? carColor;
  final String? carPlate;
  
  final int ratePerSeat;
  final String? notes;
  final RideOfferStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  // Trip details (copied from post for easy access)
  final String fromLocation;
  final String toLocation;
  final DateTime? departureTime;
  final double? fromLatitude;
  final double? fromLongitude;
  final double? toLatitude;
  final double? toLongitude;
  final int? seatsNeeded;

  RideOfferModel({
    required this.id,
    required this.postId,
    required this.passengerId,
    required this.driverId,
    required this.driverName,
    required this.driverProfileImage,
    this.carMake,
    this.carModel,
    this.carColor,
    this.carPlate,
    required this.ratePerSeat,
    this.notes,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    required this.fromLocation,
    required this.toLocation,
    this.departureTime,
    this.fromLatitude,
    this.fromLongitude,
    this.toLatitude,
    this.toLongitude,
    this.seatsNeeded,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'passengerId': passengerId,
      'driverId': driverId,
      'driverName': driverName,
      'driverProfileImage': driverProfileImage,
      'carMake': carMake,
      'carModel': carModel,
      'carColor': carColor,
      'carPlate': carPlate,
      'ratePerSeat': ratePerSeat,
      'notes': notes,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'departureTime': departureTime?.toIso8601String(),
      'fromLatitude': fromLatitude,
      'fromLongitude': fromLongitude,
      'toLatitude': toLatitude,
      'toLongitude': toLongitude,
      'seatsNeeded': seatsNeeded,
    };
  }

  factory RideOfferModel.fromMap(Map<String, dynamic> map) {
    return RideOfferModel(
      id: map['id'] ?? '',
      postId: map['postId'] ?? '',
      passengerId: map['passengerId'] ?? '',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      driverProfileImage: map['driverProfileImage'] ?? '',
      carMake: map['carMake'],
      carModel: map['carModel'],
      carColor: map['carColor'],
      carPlate: map['carPlate'],
      ratePerSeat: map['ratePerSeat'] ?? 0,
      notes: map['notes'],
      status: RideOfferStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RideOfferStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      respondedAt:
          map['respondedAt'] != null ? DateTime.parse(map['respondedAt']) : null,
      fromLocation: map['fromLocation'] ?? '',
      toLocation: map['toLocation'] ?? '',
      departureTime: map['departureTime'] != null
          ? DateTime.parse(map['departureTime'])
          : null,
      fromLatitude: map['fromLatitude']?.toDouble(),
      fromLongitude: map['fromLongitude']?.toDouble(),
      toLatitude: map['toLatitude']?.toDouble(),
      toLongitude: map['toLongitude']?.toDouble(),
      seatsNeeded: map['seatsNeeded'],
    );
  }

  RideOfferModel copyWith({
    RideOfferStatus? status,
    DateTime? respondedAt,
  }) {
    return RideOfferModel(
      id: id,
      postId: postId,
      passengerId: passengerId,
      driverId: driverId,
      driverName: driverName,
      driverProfileImage: driverProfileImage,
      carMake: carMake,
      carModel: carModel,
      carColor: carColor,
      carPlate: carPlate,
      ratePerSeat: ratePerSeat,
      notes: notes,
      status: status ?? this.status,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      fromLocation: fromLocation,
      toLocation: toLocation,
      departureTime: departureTime,
      fromLatitude: fromLatitude,
      fromLongitude: fromLongitude,
      toLatitude: toLatitude,
      toLongitude: toLongitude,
      seatsNeeded: seatsNeeded,
    );
  }
}

