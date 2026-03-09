import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String journeyId;
  final String raterId; // Person giving the rating
  final String ratedUserId; // Person being rated
  final String raterName;
  final String ratedUserName;
  final double rating; // 1-5 stars
  final String? review;
  final DateTime createdAt;
  final RatingType type; // driver_to_passenger or passenger_to_driver

  RatingModel({
    required this.id,
    required this.journeyId,
    required this.raterId,
    required this.ratedUserId,
    required this.raterName,
    required this.ratedUserName,
    required this.rating,
    this.review,
    required this.createdAt,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'journeyId': journeyId,
      'raterId': raterId,
      'ratedUserId': ratedUserId,
      'raterName': raterName,
      'ratedUserName': ratedUserName,
      'rating': rating,
      'review': review,
      'createdAt': createdAt.toIso8601String(),
      'type': type.toString().split('.').last,
    };
  }

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    return RatingModel(
      id: map['id']?.toString() ?? '',
      journeyId: map['journeyId']?.toString() ?? '',
      raterId: map['raterId']?.toString() ?? '',
      ratedUserId: map['ratedUserId']?.toString() ?? '',
      raterName: map['raterName']?.toString() ?? '',
      ratedUserName: map['ratedUserName']?.toString() ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      review: map['review']?.toString(),
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      type: _parseRatingType(map['type']),
    );
  }

  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        return dateValue;
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    return null;
  }

  static RatingType _parseRatingType(dynamic typeValue) {
    if (typeValue == null) return RatingType.passenger_to_driver;

    switch (typeValue.toString()) {
      case 'driver_to_passenger':
        return RatingType.driver_to_passenger;
      case 'passenger_to_driver':
        return RatingType.passenger_to_driver;
      default:
        return RatingType.passenger_to_driver;
    }
  }
}

enum RatingType { driver_to_passenger, passenger_to_driver }
