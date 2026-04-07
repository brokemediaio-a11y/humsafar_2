import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit a user report
  Future<bool> submitReport(ReportModel report) async {
    try {
      await _firestore
          .collection('reports')
          .doc(report.id)
          .set(report.toMap());
      
      return true;
    } catch (e) {
      debugPrint('Error submitting report: $e');
      return false;
    }
  }

  /// Check if user has already reported someone for a specific journey
  Future<bool> hasUserReported({
    required String journeyId,
    required String reporterId,
    required String reportedUserId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('journeyId', isEqualTo: journeyId)
          .where('reporterId', isEqualTo: reporterId)
          .where('reportedUserId', isEqualTo: reportedUserId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user has reported: $e');
      return false;
    }
  }

  /// Get reports made by a user
  Future<List<ReportModel>> getReportsMadeByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting reports made by user: $e');
      return [];
    }
  }

  /// Get reports against a user
  Future<List<ReportModel>> getReportsAgainstUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('reportedUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting reports against user: $e');
      return [];
    }
  }

  /// Get reports for a specific journey
  Future<List<ReportModel>> getJourneyReports(String journeyId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('journeyId', isEqualTo: journeyId)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting journey reports: $e');
      return [];
    }
  }

  /// Update report status (for admin use)
  Future<bool> updateReportStatus(String reportId, ReportStatus status) async {
    try {
      await _firestore
          .collection('reports')
          .doc(reportId)
          .update({'status': status.toString().split('.').last});
      
      return true;
    } catch (e) {
      debugPrint('Error updating report status: $e');
      return false;
    }
  }

  /// Get all pending reports (for admin use)
  Future<List<ReportModel>> getPendingReports() async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending reports: $e');
      return [];
    }
  }
}