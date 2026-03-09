enum BookingStatus { pending, approved, declined, cancelled }

class BookingRequestModel {
  final String id;
  final String postId; // The ride post ID
  final String driverId; // Post owner's user ID
  final String passengerId; // Person requesting
  final String passengerName;
  final String passengerProfileImage;
  final int seatsRequested;
  final String? notes;
  final BookingStatus status;
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
  final int? pricePerSeat;

  BookingRequestModel({
    required this.id,
    required this.postId,
    required this.driverId,
    required this.passengerId,
    required this.passengerName,
    required this.passengerProfileImage,
    required this.seatsRequested,
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
    this.pricePerSeat,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'driverId': driverId,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerProfileImage': passengerProfileImage,
      'seatsRequested': seatsRequested,
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
      'pricePerSeat': pricePerSeat,
    };
  }

  factory BookingRequestModel.fromMap(Map<String, dynamic> map) {
    return BookingRequestModel(
      id: map['id'] ?? '',
      postId: map['postId'] ?? '',
      driverId: map['driverId'] ?? '',
      passengerId: map['passengerId'] ?? '',
      passengerName: map['passengerName'] ?? '',
      passengerProfileImage: map['passengerProfileImage'] ?? '',
      seatsRequested: map['seatsRequested'] ?? 0,
      notes: map['notes'],
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.pending,
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
      pricePerSeat: map['pricePerSeat'],
    );
  }

  BookingRequestModel copyWith({
    BookingStatus? status,
    DateTime? respondedAt,
  }) {
    return BookingRequestModel(
      id: id,
      postId: postId,
      driverId: driverId,
      passengerId: passengerId,
      passengerName: passengerName,
      passengerProfileImage: passengerProfileImage,
      seatsRequested: seatsRequested,
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
      pricePerSeat: pricePerSeat,
    );
  }
}

