import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_request_model.dart';
import '../services/booking_service.dart';
import '../widgets/static_map_widget.dart';

class BookingRequestDetailScreen extends StatefulWidget {
  final BookingRequestModel bookingRequest;

  const BookingRequestDetailScreen({
    super.key,
    required this.bookingRequest,
  });

  @override
  State<BookingRequestDetailScreen> createState() =>
      _BookingRequestDetailScreenState();
}

class _BookingRequestDetailScreenState
    extends State<BookingRequestDetailScreen> {
  final BookingService _bookingService = BookingService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleApprove() async {
    setState(() => _isProcessing = true);

    final success = await _bookingService.approveBookingRequest(
      widget.bookingRequest.id,
      widget.bookingRequest.postId,
      widget.bookingRequest.seatsRequested,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Request approved successfully!')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Go back
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to approve request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDecline() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Request?'),
        content:
            const Text('Are you sure you want to decline this seat request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    final success =
        await _bookingService.declineBookingRequest(widget.bookingRequest.id);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request declined'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to decline request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('MMM d, h:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.bookingRequest.status == BookingStatus.pending;

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
          'Booking Request',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Passenger Details Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Passenger Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.grey.shade300,
                        child: widget.bookingRequest.passengerProfileImage
                                .isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  widget.bookingRequest.passengerProfileImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 32,
                                      color: Colors.grey.shade600,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.grey.shade600,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.bookingRequest.passengerName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.bookingRequest.seatsRequested} seat(s) requested',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Passenger Note
                  if (widget.bookingRequest.notes != null &&
                      widget.bookingRequest.notes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Passenger Note',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        widget.bookingRequest.notes!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Trip Details Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Route
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFF49977a),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 3,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF49977a).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFF49977a),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pickup',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              widget.bookingRequest.fromLocation,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Drop-off',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              widget.bookingRequest.toLocation,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Map - Use static map for detail screens to prevent buffer exhaustion
                  if (widget.bookingRequest.fromLatitude != null &&
                      widget.bookingRequest.fromLongitude != null &&
                      widget.bookingRequest.toLatitude != null &&
                      widget.bookingRequest.toLongitude != null)
                    StaticMapWidget(
                      fromLatitude: widget.bookingRequest.fromLatitude,
                      fromLongitude: widget.bookingRequest.fromLongitude,
                      toLatitude: widget.bookingRequest.toLatitude,
                      toLongitude: widget.bookingRequest.toLongitude,
                      fromLocation: widget.bookingRequest.fromLocation,
                      toLocation: widget.bookingRequest.toLocation,
                      height: 200,
                    ),

                  const SizedBox(height: 20),

                  // Trip Info
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.access_time,
                          label: 'Departure',
                          value: widget.bookingRequest.departureTime != null
                              ? _formatTime(widget.bookingRequest.departureTime!)
                              : 'Not specified',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.payments,
                          label: 'Price',
                          value: widget.bookingRequest.pricePerSeat != null
                              ? 'Rs. ${widget.bookingRequest.pricePerSeat! * widget.bookingRequest.seatsRequested}'
                              : 'Not specified',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.airline_seat_recline_normal,
                          label: 'Seats',
                          value: '${widget.bookingRequest.seatsRequested} requested',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.access_time,
                          label: 'Requested',
                          value: DateFormat('MMM d, h:mm a')
                              .format(widget.bookingRequest.createdAt),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100), // Space for bottom buttons
          ],
        ),
      ),

      // Bottom Action Buttons (only show if pending)
      bottomNavigationBar: isPending && !_isProcessing
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _handleDecline,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Decline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _handleApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF49977a),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Approve',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _isProcessing
              ? Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF49977a),
                    ),
                  ),
                )
              : null,
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: const Color(0xFF49977a),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}

// Isolated map widget for booking request detail to prevent rebuilds

