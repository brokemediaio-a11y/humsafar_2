import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reporterId; // Person making the report
  final String reportedUserId; // Person being reported
  final String reporterName;
  final String reportedUserName;
  final String journeyId;
  final ReportReason reason;
  final String? description;
  final DateTime createdAt;
  final ReportStatus status;
  final ReportType type; // driver_reporting_passenger or passenger_reporting_driver

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reporterName,
    required this.reportedUserName,
    required this.journeyId,
    required this.reason,
    this.description,
    required this.createdAt,
    required this.status,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reporterName': reporterName,
      'reportedUserName': reportedUserName,
      'journeyId': journeyId,
      'reason': reason.toString().split('.').last,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id']?.toString() ?? '',
      reporterId: map['reporterId']?.toString() ?? '',
      reportedUserId: map['reportedUserId']?.toString() ?? '',
      reporterName: map['reporterName']?.toString() ?? '',
      reportedUserName: map['reportedUserName']?.toString() ?? '',
      journeyId: map['journeyId']?.toString() ?? '',
      reason: _parseReportReason(map['reason']),
      description: map['description']?.toString(),
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      status: _parseReportStatus(map['status']),
      type: _parseReportType(map['type']),
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

  static ReportReason _parseReportReason(dynamic reasonValue) {
    if (reasonValue == null) return ReportReason.inappropriate_behavior;

    switch (reasonValue.toString()) {
      case 'inappropriate_behavior':
        return ReportReason.inappropriate_behavior;
      case 'harassment':
        return ReportReason.harassment;
      case 'unsafe_driving':
        return ReportReason.unsafe_driving;
      case 'no_show':
        return ReportReason.no_show;
      case 'late_arrival':
        return ReportReason.late_arrival;
      case 'vehicle_condition':
        return ReportReason.vehicle_condition;
      case 'route_deviation':
        return ReportReason.route_deviation;
      case 'payment_issues':
        return ReportReason.payment_issues;
      case 'other':
        return ReportReason.other;
      default:
        return ReportReason.inappropriate_behavior;
    }
  }

  static ReportStatus _parseReportStatus(dynamic statusValue) {
    if (statusValue == null) return ReportStatus.pending;

    switch (statusValue.toString()) {
      case 'pending':
        return ReportStatus.pending;
      case 'under_review':
        return ReportStatus.under_review;
      case 'resolved':
        return ReportStatus.resolved;
      case 'dismissed':
        return ReportStatus.dismissed;
      default:
        return ReportStatus.pending;
    }
  }

  static ReportType _parseReportType(dynamic typeValue) {
    if (typeValue == null) return ReportType.passenger_reporting_driver;

    switch (typeValue.toString()) {
      case 'driver_reporting_passenger':
        return ReportType.driver_reporting_passenger;
      case 'passenger_reporting_driver':
        return ReportType.passenger_reporting_driver;
      default:
        return ReportType.passenger_reporting_driver;
    }
  }
}

enum ReportReason {
  inappropriate_behavior,
  harassment,
  unsafe_driving,
  no_show,
  late_arrival,
  vehicle_condition,
  route_deviation,
  payment_issues,
  other,
}

enum ReportStatus {
  pending,
  under_review,
  resolved,
  dismissed,
}

enum ReportType {
  driver_reporting_passenger,
  passenger_reporting_driver,
}

extension ReportReasonExtension on ReportReason {
  String get displayName {
    switch (this) {
      case ReportReason.inappropriate_behavior:
        return 'Inappropriate Behavior';
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.unsafe_driving:
        return 'Unsafe Driving';
      case ReportReason.no_show:
        return 'No Show';
      case ReportReason.late_arrival:
        return 'Late Arrival';
      case ReportReason.vehicle_condition:
        return 'Poor Vehicle Condition';
      case ReportReason.route_deviation:
        return 'Route Deviation';
      case ReportReason.payment_issues:
        return 'Payment Issues';
      case ReportReason.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case ReportReason.inappropriate_behavior:
        return 'Rude, disrespectful, or unprofessional conduct';
      case ReportReason.harassment:
        return 'Unwanted advances, threats, or intimidation';
      case ReportReason.unsafe_driving:
        return 'Reckless, aggressive, or dangerous driving';
      case ReportReason.no_show:
        return 'Failed to show up for the ride';
      case ReportReason.late_arrival:
        return 'Significantly late without communication';
      case ReportReason.vehicle_condition:
        return 'Dirty, damaged, or unsafe vehicle';
      case ReportReason.route_deviation:
        return 'Took unauthorized detours or wrong route';
      case ReportReason.payment_issues:
        return 'Refused to pay or payment disputes';
      case ReportReason.other:
        return 'Other issues not listed above';
    }
  }
}