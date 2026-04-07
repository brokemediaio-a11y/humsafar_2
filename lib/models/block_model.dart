import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BlockModel {
  final String id;
  final String blockerId; // User who is blocking
  final String blockedUserId; // User being blocked
  final String blockerName;
  final String blockedUserName;
  final DateTime createdAt;
  final String? reason; // Optional reason for blocking

  BlockModel({
    required this.id,
    required this.blockerId,
    required this.blockedUserId,
    required this.blockerName,
    required this.blockedUserName,
    required this.createdAt,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'blockerId': blockerId,
      'blockedUserId': blockedUserId,
      'blockerName': blockerName,
      'blockedUserName': blockedUserName,
      'createdAt': createdAt.toIso8601String(),
      'reason': reason,
    };
  }

  factory BlockModel.fromMap(Map<String, dynamic> map) {
    return BlockModel(
      id: map['id']?.toString() ?? '',
      blockerId: map['blockerId']?.toString() ?? '',
      blockedUserId: map['blockedUserId']?.toString() ?? '',
      blockerName: map['blockerName']?.toString() ?? '',
      blockedUserName: map['blockedUserName']?.toString() ?? '',
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      reason: map['reason']?.toString(),
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
}