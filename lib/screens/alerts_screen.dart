import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';
import '../services/booking_service.dart';
import '../services/ride_offer_service.dart';
import '../services/auth_service.dart';
import 'booking_request_detail_screen.dart';
import 'ride_offer_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final BookingService _bookingService = BookingService();
  final RideOfferService _rideOfferService = RideOfferService();
  final AuthService _authService = AuthService();

  void _handleAlertTap(AlertModel alert) async {
    // Mark as read
    if (!alert.isRead) {
      await _bookingService.markAlertAsRead(alert.id);
    }

    // Navigate based on alert type
    if (alert.relatedId != null) {
      // Handle booking requests
      if (alert.type == AlertType.bookingRequest ||
          alert.type == AlertType.bookingApproved ||
          alert.type == AlertType.bookingDeclined) {
        if (!mounted) return;

        final booking =
            await _bookingService.getBookingRequest(alert.relatedId!);
        if (booking == null) return;

        // For booking requests (driver receives), navigate to detail screen
        if (alert.type == AlertType.bookingRequest && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BookingRequestDetailScreen(bookingRequest: booking),
            ),
          );
        }
        // For other types, just show a message
        else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(alert.message)),
          );
        }
      }
      // Handle ride offers
      else if (alert.type == AlertType.rideOffer ||
               alert.type == AlertType.rideOfferAccepted ||
               alert.type == AlertType.rideOfferDeclined) {
        if (!mounted) return;

        final rideOffer =
            await _rideOfferService.getRideOffer(alert.relatedId!);
        if (rideOffer == null) return;

        // For ride offers (passenger receives), navigate to detail screen
        if (alert.type == AlertType.rideOffer && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RideOfferDetailScreen(rideOffer: rideOffer),
            ),
          );
        }
        // For other types, just show a message
        else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(alert.message)),
          );
        }
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.bookingRequest:
        return Icons.person_add;
      case AlertType.bookingApproved:
        return Icons.check_circle;
      case AlertType.bookingDeclined:
        return Icons.cancel;
      case AlertType.bookingCancelled:
        return Icons.event_busy;
      case AlertType.rideOffer:
        return Icons.directions_car;
      case AlertType.rideOfferAccepted:
        return Icons.check_circle;
      case AlertType.rideOfferDeclined:
        return Icons.cancel;
      case AlertType.general:
        return Icons.notifications;
    }
  }

  Color _getAlertColor(AlertType type) {
    switch (type) {
      case AlertType.bookingRequest:
        return const Color(0xFF49977a);
      case AlertType.bookingApproved:
        return Colors.green;
      case AlertType.bookingDeclined:
        return Colors.red;
      case AlertType.bookingCancelled:
        return Colors.orange;
      case AlertType.rideOffer:
        return const Color(0xFF49977a);
      case AlertType.rideOfferAccepted:
        return Colors.green;
      case AlertType.rideOfferDeclined:
        return Colors.red;
      case AlertType.general:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view alerts')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Alerts',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<AlertModel>>(
        stream: _bookingService.getUserAlerts(currentUser.uid),
        builder: (context, snapshot) {
          debugPrint('🔔 Alerts Stream Update:');
          debugPrint('   Connection: ${snapshot.connectionState}');
          debugPrint('   Has Error: ${snapshot.hasError}');
          debugPrint('   Error: ${snapshot.error}');
          debugPrint('   Has Data: ${snapshot.hasData}');
          debugPrint('   Alerts Count: ${snapshot.data?.length ?? 0}');
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF49977a),
              ),
            );
          }

          if (snapshot.hasError) {
            debugPrint('❌ Alert Stream Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading alerts',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final alerts = snapshot.data ?? [];

          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No alerts yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see notifications here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return GestureDetector(
                onTap: () => _handleAlertTap(alert),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: alert.isRead
                        ? Colors.white
                        : const Color(0xFF49977a).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: alert.isRead
                          ? Colors.grey.shade200
                          : const Color(0xFF49977a).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getAlertColor(alert.type).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getAlertIcon(alert.type),
                          color: _getAlertColor(alert.type),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    alert.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: alert.isRead
                                          ? FontWeight.w600
                                          : FontWeight.bold,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                if (!alert.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF49977a),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert.message,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTime(alert.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Arrow
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

