import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ride_offer_model.dart';
import '../services/ride_offer_service.dart';
import '../widgets/static_map_widget.dart';

class RideOfferDetailScreen extends StatefulWidget {
  final RideOfferModel rideOffer;

  const RideOfferDetailScreen({
    super.key,
    required this.rideOffer,
  });

  @override
  State<RideOfferDetailScreen> createState() => _RideOfferDetailScreenState();
}

class _RideOfferDetailScreenState extends State<RideOfferDetailScreen> {
  final RideOfferService _rideOfferService = RideOfferService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleAccept() async {
    setState(() => _isProcessing = true);

    final success = await _rideOfferService.acceptRideOffer(widget.rideOffer.id);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Ride offer accepted successfully!')),
            ],
          ),
          backgroundColor: Colors.green,
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
          content: Text('Failed to accept offer'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDecline() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Offer?'),
        content: const Text('Are you sure you want to decline this ride offer?'),
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

    final success = await _rideOfferService.declineRideOffer(widget.rideOffer.id);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer declined'),
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
          content: Text('Failed to decline offer'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getCarInfo() {
    final parts = <String>[];
    if (widget.rideOffer.carMake != null) parts.add(widget.rideOffer.carMake!);
    if (widget.rideOffer.carModel != null) parts.add(widget.rideOffer.carModel!);
    if (widget.rideOffer.carColor != null) parts.add(widget.rideOffer.carColor!);
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.rideOffer.status == RideOfferStatus.pending;

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
          'Ride Offer',
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
            // Driver Details Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Driver Details',
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
                        child: widget.rideOffer.driverProfileImage.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  widget.rideOffer.driverProfileImage,
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
                              widget.rideOffer.driverName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF49977a).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Driver',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF49977a),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Car Details
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Car Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        color: Color(0xFF49977a),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getCarInfo(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (widget.rideOffer.carPlate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.badge,
                          color: Color(0xFF49977a),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.rideOffer.carPlate!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Rate
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.payments,
                          color: Colors.green.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rate Per Seat',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              'Rs. ${widget.rideOffer.ratePerSeat}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Driver Notes
                  if (widget.rideOffer.notes != null &&
                      widget.rideOffer.notes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Driver Note',
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
                        widget.rideOffer.notes!,
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
                              widget.rideOffer.fromLocation,
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
                              widget.rideOffer.toLocation,
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
                  if (widget.rideOffer.fromLatitude != null &&
                      widget.rideOffer.fromLongitude != null &&
                      widget.rideOffer.toLatitude != null &&
                      widget.rideOffer.toLongitude != null)
                    StaticMapWidget(
                      fromLatitude: widget.rideOffer.fromLatitude,
                      fromLongitude: widget.rideOffer.fromLongitude,
                      toLatitude: widget.rideOffer.toLatitude,
                      toLongitude: widget.rideOffer.toLongitude,
                      fromLocation: widget.rideOffer.fromLocation,
                      toLocation: widget.rideOffer.toLocation,
                      height: 200,
                    ),

                  const SizedBox(height: 20),

                  // Trip Info
                  if (widget.rideOffer.departureTime != null)
                    _buildInfoItem(
                      icon: Icons.access_time,
                      label: 'Departure',
                      value: DateFormat('MMM d, h:mm a')
                          .format(widget.rideOffer.departureTime!),
                    ),
                  
                  if (widget.rideOffer.seatsNeeded != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      icon: Icons.airline_seat_recline_normal,
                      label: 'Seats Needed',
                      value: '${widget.rideOffer.seatsNeeded} seats',
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 100),
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
                        onPressed: _handleAccept,
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
                          'Accept',
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
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF49977a),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Isolated map widget for ride offer detail to prevent rebuilds

