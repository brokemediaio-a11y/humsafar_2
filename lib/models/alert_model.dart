enum AlertType {
  bookingRequest, // Driver receives: "X requested a seat"
  bookingApproved, // Passenger receives: "Driver approved your request"
  bookingDeclined, // Passenger receives: "Driver declined your request"
  bookingCancelled, // Driver receives: "X cancelled their request"
  rideOffer, // Passenger receives: "X offered a ride"
  rideOfferAccepted, // Driver receives: "Passenger accepted your offer"
  rideOfferDeclined, // Driver receives: "Passenger declined your offer"
  general, // Other notifications
}

class AlertModel {
  final String id;
  final String userId; // Who receives this alert
  final AlertType type;
  final String title;
  final String message;
  final String? relatedId; // booking request ID, post ID, etc.
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // Extra data (user info, etc.)

  AlertModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: AlertType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AlertType.general,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      relatedId: map['relatedId'],
      isRead: map['isRead'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  AlertModel copyWith({
    bool? isRead,
  }) {
    return AlertModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      relatedId: relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      metadata: metadata,
    );
  }
}

