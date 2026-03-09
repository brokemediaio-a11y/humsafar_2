import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post_model.dart';
import '../models/ride_offer_model.dart';
import '../services/ride_offer_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class OfferRideDialog extends StatefulWidget {
  final PostModel post;

  const OfferRideDialog({
    super.key,
    required this.post,
  });

  @override
  State<OfferRideDialog> createState() => _OfferRideDialogState();
}

class _OfferRideDialogState extends State<OfferRideDialog> {
  final _formKey = GlobalKey<FormState>();
  final _carMakeController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carColorController = TextEditingController();
  final _carPlateController = TextEditingController();
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();
  final _rideOfferService = RideOfferService();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void dispose() {
    _carMakeController.dispose();
    _carModelController.dispose();
    _carColorController.dispose();
    _carPlateController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _maxRate {
    if (widget.post.distanceKm != null) {
      // Formula: (35 * distanceKm) * 1.10 (includes 10% platform fee)
      const double pricePerKm = 35.0;
      const double platformFeeMultiplier = 1.10;
      return ((pricePerKm * widget.post.distanceKm!) * platformFeeMultiplier).round();
    }
    return 1000; // Default max if distance not available
  }

  Future<void> _handleOffer() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _authService.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to offer a ride')),
      );
      return;
    }

    // Get user data
    final userData = await _firestoreService.getUser(user.uid);
    if (userData == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not found')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Create ride offer
    final offer = RideOfferModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: widget.post.id,
      passengerId: widget.post.userId,
      driverId: user.uid,
      driverName: userData.fullName,
      driverProfileImage: '',
      carMake: _carMakeController.text.trim().isEmpty
          ? null
          : _carMakeController.text.trim(),
      carModel: _carModelController.text.trim().isEmpty
          ? null
          : _carModelController.text.trim(),
      carColor: _carColorController.text.trim().isEmpty
          ? null
          : _carColorController.text.trim(),
      carPlate: _carPlateController.text.trim().isEmpty
          ? null
          : _carPlateController.text.trim(),
      ratePerSeat: int.parse(_rateController.text),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      status: RideOfferStatus.pending,
      createdAt: DateTime.now(),
      fromLocation: widget.post.fromLocation,
      toLocation: widget.post.toLocation,
      departureTime: widget.post.departureTime,
      fromLatitude: widget.post.fromLatitude,
      fromLongitude: widget.post.fromLongitude,
      toLatitude: widget.post.toLatitude,
      toLongitude: widget.post.toLongitude,
      seatsNeeded: widget.post.seatsNeeded,
    );

    final success = await _rideOfferService.createRideOffer(offer);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context, true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Ride offer sent successfully!')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send offer. You may already have a pending offer.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF49977a).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: Color(0xFF49977a),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Offer Ride',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Car Details Section
                const Text(
                  'Car Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Car Make
                TextFormField(
                  controller: _carMakeController,
                  decoration: InputDecoration(
                    labelText: 'Make (e.g., Honda)',
                    hintText: 'Car make',
                    prefixIcon: const Icon(Icons.directions_car),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter car make';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Car Model
                TextFormField(
                  controller: _carModelController,
                  decoration: InputDecoration(
                    labelText: 'Model (e.g., Civic)',
                    hintText: 'Car model',
                    prefixIcon: const Icon(Icons.drive_eta),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter car model';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Car Color & Plate in row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _carColorController,
                        decoration: InputDecoration(
                          labelText: 'Color',
                          hintText: 'White',
                          prefixIcon: const Icon(Icons.palette),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _carPlateController,
                        decoration: InputDecoration(
                          labelText: 'Plate',
                          hintText: 'ABC-123',
                          prefixIcon: const Icon(Icons.badge),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Rate Section
                const Text(
                  'Rate Per Seat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Maximum rate: Rs. $_maxRate (35 × ${widget.post.distanceKm?.toStringAsFixed(1) ?? "??"} km + 10% platform fee)',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _rateController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Rate per seat (Rs.)',
                    hintText: 'Enter rate',
                    prefixIcon: const Icon(Icons.payments),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter rate';
                    }
                    final rate = int.tryParse(value);
                    if (rate == null || rate <= 0) {
                      return 'Please enter a valid rate';
                    }
                    if (rate > _maxRate) {
                      return 'Rate cannot exceed Rs. $_maxRate';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Notes
                const Text(
                  'Notes (Optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Comfortable car, AC available...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleOffer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF49977a),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Offer Ride',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

