import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post_model.dart';
import '../models/booking_request_model.dart';
import '../models/user_model.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/user_mention_field.dart';
import '../utils/mention_parser.dart';

class RequestSeatDialog extends StatefulWidget {
  final PostModel post;

  const RequestSeatDialog({
    super.key,
    required this.post,
  });

  @override
  State<RequestSeatDialog> createState() => _RequestSeatDialogState();
}

class _RequestSeatDialogState extends State<RequestSeatDialog> {
  final _formKey = GlobalKey<FormState>();
  final _seatsController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  final _bookingService = BookingService();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _mentionParser = MentionParser();
  bool _isLoading = false;

  @override
  void dispose() {
    _seatsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _authService.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to request a seat')),
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

    final seatsRequested = int.parse(_seatsController.text);

    // Additional validation for multi-seat requests
    if (seatsRequested > 1 && _notesController.text.trim().isEmpty) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tag other passengers in the notes for multi-seat requests'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Parse mentions from notes
    final notesText = _notesController.text.trim();
    List<UserModel> taggedUsers = [];
    
    if (seatsRequested > 1 && notesText.isNotEmpty) {
      try {
        taggedUsers = await _mentionParser.parseMentionsToUsers(notesText);
      } catch (e) {
        debugPrint('Error parsing mentions: $e');
      }
    }

    // Calculate total seats needed (requester + tagged users)
    final totalSeatsNeeded = 1 + taggedUsers.length; // 1 for requester + 1 per tagged user
    
    // Validate total seats
    if (seatsRequested != totalSeatsNeeded) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Number of seats ($seatsRequested) must match number of tagged users + 1 (you). '
            'You tagged ${taggedUsers.length} user(s).',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Check if enough seats available
    if (widget.post.seatsAvailable != null &&
        seatsRequested > widget.post.seatsAvailable!) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough seats available')),
      );
      return;
    }

    // Create booking request for the requester (1 seat)
    final requesterBooking = BookingRequestModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: widget.post.id,
      driverId: widget.post.userId,
      passengerId: user.uid,
      passengerName: userData.fullName,
      passengerProfileImage: userData.profileImageUrl ?? '',
      seatsRequested: 1, // Requester always gets 1 seat
      notes: notesText.isEmpty ? null : notesText,
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
      fromLocation: widget.post.fromLocation,
      toLocation: widget.post.toLocation,
      departureTime: widget.post.departureTime,
      fromLatitude: widget.post.fromLatitude,
      fromLongitude: widget.post.fromLongitude,
      toLatitude: widget.post.toLatitude,
      toLongitude: widget.post.toLongitude,
      pricePerSeat: widget.post.price,
    );

    // Create booking request for requester
    bool success = await _bookingService.createBookingRequest(requesterBooking);

    // Create booking requests for tagged users (1 seat each)
    if (success && taggedUsers.isNotEmpty) {
      for (final taggedUser in taggedUsers) {
        // Get tagged user's full profile data
        final taggedUserData = await _firestoreService.getUser(taggedUser.uid);
        if (taggedUserData == null) continue;

        final taggedBooking = BookingRequestModel(
          id: '${DateTime.now().millisecondsSinceEpoch}_${taggedUser.uid}',
          postId: widget.post.id,
          driverId: widget.post.userId,
          passengerId: taggedUser.uid,
          passengerName: taggedUserData.fullName,
          passengerProfileImage: taggedUserData.profileImageUrl ?? '',
          seatsRequested: 1, // Each tagged user gets 1 seat
          notes: 'Tagged by ${userData.fullName}',
          status: BookingStatus.pending,
          createdAt: DateTime.now(),
          fromLocation: widget.post.fromLocation,
          toLocation: widget.post.toLocation,
          departureTime: widget.post.departureTime,
          fromLatitude: widget.post.fromLatitude,
          fromLongitude: widget.post.fromLongitude,
          toLatitude: widget.post.toLatitude,
          toLongitude: widget.post.toLongitude,
          pricePerSeat: widget.post.price,
        );

        final taggedSuccess = await _bookingService.createBookingRequest(taggedBooking);
        if (!taggedSuccess) {
          debugPrint('Failed to create booking for tagged user: ${taggedUser.fullName}');
        }
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context, true); // Return true to indicate success
      
      // Show success toast
      final taggedCount = taggedUsers.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  taggedCount > 0
                      ? 'Seat request sent! $taggedCount tagged user(s) will also receive booking requests.'
                      : 'Seat request sent successfully!',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send request. You may already have a pending request.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets,
      duration: const Duration(milliseconds: 100),
      curve: Curves.decelerate,
      child: MediaQuery.removeViewInsets(
        removeBottom: true,
        context: context,
        child: Center(
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                      Icons.event_seat,
                      color: Color(0xFF49977a),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Request Seat',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Available seats info
              if (widget.post.seatsAvailable != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.post.seatsAvailable} seats available',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Number of seats
              const Text(
                'Number of seats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _seatsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Enter number of seats',
                  prefixIcon: const Icon(Icons.airline_seat_recline_normal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of seats';
                  }
                  final seats = int.tryParse(value);
                  if (seats == null || seats <= 0) {
                    return 'Please enter a valid number';
                  }
                  if (widget.post.seatsAvailable != null &&
                      seats > widget.post.seatsAvailable!) {
                    return 'Only ${widget.post.seatsAvailable} seats available';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Notes
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _seatsController,
                builder: (context, value, child) {
                  final seatsRequested = int.tryParse(value.text) ?? 1;
                  final isMultiSeat = seatsRequested > 1;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isMultiSeat ? 'Notes (Required)' : 'Notes (Optional)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isMultiSeat ? Colors.red.shade700 : null,
                            ),
                          ),
                          if (isMultiSeat) ...[
                            const SizedBox(width: 4),
                            Text(
                              '*',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (isMultiSeat) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tag other passengers using @ (e.g., @John @Sarah)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _seatsController,
                builder: (context, value, child) {
                  final seatsRequested = int.tryParse(value.text) ?? 1;
                  final isMultiSeat = seatsRequested > 1;
                  
                  return UserMentionField(
                    controller: _notesController,
                    maxLines: 3,
                    isRequired: isMultiSeat,
                    hintText: isMultiSeat 
                        ? 'Type @ to tag passengers - I\'m at the main gate'
                        : 'I\'m at the main gate. Can you stop near the library?',
                    validator: isMultiSeat ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please tag other passengers for multi-seat requests';
                      }
                      if (!value.contains('@')) {
                        return 'Please tag passengers using @ symbol (e.g., @John @Sarah)';
                      }
                      return null;
                    } : null,
                  );
                },
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
                      onPressed: _isLoading ? null : _handleConfirm,
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
                              'Confirm',
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
            ),
          ),
        ),
      ),
    );
  }
}

