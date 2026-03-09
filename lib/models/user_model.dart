import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String cnic;
  final DateTime dateOfBirth;
  final String studentId;
  final String? studentCardFront;
  final String? studentCardBack;
  final String? cnicFront;
  final String? cnicBack;
  final String? licenseFront;
  final String? licenseBack;
  final bool hasCar;
  final DateTime createdAt;
  final bool isVerified;
  
  // Additional fields for profile screen
  final String? profileImageUrl;
  final DateTime? updatedAt;
  final double rating;
  final int totalRides;

  // Computed property for full name
  String get fullName => '$firstName $lastName'.trim();

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.cnic,
    required this.dateOfBirth,
    required this.studentId,
    this.studentCardFront,
    this.studentCardBack,
    this.cnicFront,
    this.cnicBack,
    this.licenseFront,
    this.licenseBack,
    this.hasCar = false,
    required this.createdAt,
    this.isVerified = false,
    this.profileImageUrl,
    this.updatedAt,
    this.rating = 0.0,
    this.totalRides = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName, // Store for backward compatibility
      'email': email,
      'phone': phone,
      'phoneNumber': phone, // Alias for backward compatibility
      'cnic': cnic,
      'cnicNumber': cnic, // Alias for backward compatibility
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'studentId': studentId,
      'studentCardFront': studentCardFront,
      'studentCardBack': studentCardBack,
      'cnicFront': cnicFront,
      'cnicBack': cnicBack,
      'licenseFront': licenseFront,
      'licenseBack': licenseBack,
      'hasCar': hasCar,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isVerified': isVerified,
      'profileImageUrl': profileImageUrl,
      'rating': rating,
      'totalRides': totalRides,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    try {
      // Handle date parsing safely
      DateTime? parseDate(dynamic dateValue) {
        if (dateValue == null) return null;
        if (dateValue is DateTime) return dateValue;
        if (dateValue is String) {
          try {
            return DateTime.parse(dateValue);
          } catch (e) {
            return null;
          }
        }
        if (dateValue is Timestamp) {
          return dateValue.toDate();
        }
        return null;
      }

      return UserModel(
        uid: map['uid']?.toString() ?? '',
        firstName: map['firstName']?.toString() ?? '',
        lastName: map['lastName']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        phone: map['phone']?.toString() ?? map['phoneNumber']?.toString() ?? '',
        cnic: map['cnic']?.toString() ?? map['cnicNumber']?.toString() ?? '',
        dateOfBirth: parseDate(map['dateOfBirth']) ?? DateTime.now(),
        studentId: map['studentId']?.toString() ?? '',
      studentCardFront: map['studentCardFront']?.toString(),
      studentCardBack: map['studentCardBack']?.toString(),
      cnicFront: map['cnicFront']?.toString(),
      cnicBack: map['cnicBack']?.toString(),
      licenseFront: map['licenseFront']?.toString(),
      licenseBack: map['licenseBack']?.toString(),
      hasCar: map['hasCar'] == true,
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      isVerified: map['isVerified'] == true,
        profileImageUrl: map['profileImageUrl']?.toString(),
        updatedAt: parseDate(map['updatedAt']),
        rating: (map['rating'] ?? 0.0).toDouble(),
        totalRides: (map['totalRides'] ?? 0) as int,
      );
    } catch (e) {
      debugPrint('Error parsing UserModel: $e');
      rethrow;
    }
  }

  UserModel copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? cnic,
    DateTime? dateOfBirth,
    String? studentId,
    String? studentCardFront,
    String? studentCardBack,
    String? cnicFront,
    String? cnicBack,
    String? licenseFront,
    String? licenseBack,
    bool? hasCar,
    DateTime? createdAt,
    bool? isVerified,
    String? profileImageUrl,
    DateTime? updatedAt,
    double? rating,
    int? totalRides,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      cnic: cnic ?? this.cnic,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      studentId: studentId ?? this.studentId,
      studentCardFront: studentCardFront ?? this.studentCardFront,
      studentCardBack: studentCardBack ?? this.studentCardBack,
      cnicFront: cnicFront ?? this.cnicFront,
      cnicBack: cnicBack ?? this.cnicBack,
      licenseFront: licenseFront ?? this.licenseFront,
      licenseBack: licenseBack ?? this.licenseBack,
      hasCar: hasCar ?? this.hasCar,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, fullName: $fullName, email: $email, phone: $phone, isVerified: $isVerified, rating: $rating, totalRides: $totalRides)';
  }
}