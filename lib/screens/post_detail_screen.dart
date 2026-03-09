import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart';
import '../models/booking_request_model.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/chat_service.dart';
import '../services/firestore_service.dart';
import '../widgets/request_seat_dialog.dart';
import '../widgets/offer_ride_dialog.dart';
import '../widgets/static_map_widget.dart';
import 'chat_detail_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final AuthService _authService = AuthService();
  final BookingService _bookingService = BookingService();
  final ChatService _chatService = ChatService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _hasPendingRequest = false;
  bool _isCheckingRequest = true;

  @override
  void initState() {
    super.initState();
    _checkPendingRequest();
  }

  Future<void> _checkPendingRequest() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || widget.post.type != PostType.driver) {
      setState(() => _isCheckingRequest = false);
      return;
    }

    final hasPending = await _bookingService.hasPendingRequest(
      currentUser.uid,
      widget.post.id,
    );
    
    if (mounted) {
      setState(() {
        _hasPendingRequest = hasPending;
        _isCheckingRequest = false;
      });
    }
  }


  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      return 'Today, ${DateFormat('h:mm a').format(time)}';
    }
    return DateFormat('MMM d, h:mm a').format(time);
  }

  void _handleRequestSeat() async {
    // Show request seat dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RequestSeatDialog(post: widget.post),
    );

    // If request was successful, refresh the pending status
    if (result == true && mounted) {
      _checkPendingRequest();
    }
  }

  bool _isButtonDisabled() {
    if (widget.post.type == PostType.driver) {
      // Disable if seats are 0 or user has pending request
      return (widget.post.seatsAvailable != null && widget.post.seatsAvailable! <= 0) || 
             _hasPendingRequest;
    }
    return false;
  }

  VoidCallback? _getButtonAction() {
    if (_isButtonDisabled()) return null;
    
    return widget.post.type == PostType.driver
        ? _handleRequestSeat
        : _handleOfferRide;
  }

  Widget _buildButtonChild() {
    if (_isCheckingRequest && widget.post.type == PostType.driver) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    String buttonText;
    if (widget.post.type == PostType.driver) {
      if (widget.post.seatsAvailable != null && widget.post.seatsAvailable! <= 0) {
        buttonText = 'Fully Booked';
      } else if (_hasPendingRequest) {
        buttonText = 'Request Pending';
      } else {
        buttonText = 'Request Seat';
      }
    } else {
      buttonText = 'Offer Ride';
    }

    return Text(
      buttonText,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _handleOfferRide() async {
    // Show offer ride dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => OfferRideDialog(post: widget.post),
    );

    // If offer was successful, the dialog already shows a toast
    if (result == true && mounted) {
      // Optionally refresh or show additional feedback
    }
  }

  void _handleMessage() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to send messages')),
      );
      return;
    }

    // Get current user data
    final currentUserData = await _firestoreService.getUser(currentUser.uid);
    if (currentUserData == null || !mounted) return;

    // Get or create chat
    final chatId = await _chatService.getOrCreateChat(
      currentUserId: currentUser.uid,
      currentUserName: currentUserData.fullName,
      currentUserImage: '',
      otherUserId: widget.post.userId,
      otherUserName: widget.post.userName,
      otherUserImage: widget.post.userProfileImageUrl,
    );

    if (!mounted) return;

    // Navigate to chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          chatId: chatId,
          otherUserId: widget.post.userId,
          otherUserName: widget.post.userName,
          otherUserImage: widget.post.userProfileImageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    final isOwnPost = currentUser?.uid == widget.post.userId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.post.type == PostType.driver ? 'Driver Details' : 'Passenger Details',
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1F2937)),
            onPressed: () {
              // TODO: Show options menu (report, share, etc.)
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey.shade300,
                    child: widget.post.userProfileImageUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              widget.post.userProfileImageUrl,
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
                        Row(
                          children: [
                            Text(
                              widget.post.userName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.post.isVerified) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF49977a),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.post.type == PostType.driver ? 'Driver' : 'Passenger',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF49977a).withValues(alpha: 0.3),
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
                              'From',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              widget.post.fromLocation,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'To',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              widget.post.toLocation,
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
                  if (widget.post.fromLatitude != null &&
                      widget.post.fromLongitude != null &&
                      widget.post.toLatitude != null &&
                      widget.post.toLongitude != null)
                    StaticMapWidget(
                      fromLatitude: widget.post.fromLatitude,
                      fromLongitude: widget.post.fromLongitude,
                      toLatitude: widget.post.toLatitude,
                      toLongitude: widget.post.toLongitude,
                      fromLocation: widget.post.fromLocation,
                      toLocation: widget.post.toLocation,
                      height: 200,
                    ),

                  const SizedBox(height: 20),

                  // Details Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.access_time,
                          label: 'Departure',
                          value: widget.post.departureTime != null
                              ? _formatTime(widget.post.departureTime!)
                              : 'Not specified',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.airline_seat_recline_normal,
                          label: 'Seats',
                          value: widget.post.seatsAvailable != null
                              ? '${widget.post.seatsAvailable} available'
                              : widget.post.seatsNeeded != null
                                  ? '${widget.post.seatsNeeded} needed'
                                  : 'Not specified',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.payments,
                          label: 'Price per seat',
                          value: widget.post.price != null
                              ? 'Rs. ${widget.post.price}'
                              : 'Not specified',
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (widget.post.distanceKm != null)
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.straighten,
                            label: 'Distance',
                            value: '${widget.post.distanceKm!.toStringAsFixed(1)} km',
                          ),
                        ),
                    ],
                  ),

                  // Car details (only for drivers)
                  if (widget.post.type == PostType.driver &&
                      (widget.post.carMake != null ||
                          widget.post.carModel != null ||
                          widget.post.carColor != null)) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Car Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
                          [
                            if (widget.post.carMake != null) widget.post.carMake,
                            if (widget.post.carModel != null) widget.post.carModel,
                            if (widget.post.carColor != null) widget.post.carColor,
                          ].join(' • '),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (widget.post.carPlate != null) ...[
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
                            widget.post.carPlate!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],

                  // Notes
                  if (widget.post.notes != null && widget.post.notes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.post.notes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],

                  // Tags
                  if (widget.post.tags != null && widget.post.tags!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.post.tags!.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF49977a).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF49977a).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF49977a),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Passenger List - Real-time approved bookings
            if (widget.post.type == PostType.driver)
              StreamBuilder<List<BookingRequestModel>>(
                stream: _bookingService.getPostBookingRequests(widget.post.id),
                builder: (context, snapshot) {
                  // Filter only approved bookings
                  final approvedBookings = (snapshot.data ?? [])
                      .where((booking) => booking.status == BookingStatus.approved)
                      .toList();

                  return Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Passenger List',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${approvedBookings.length} confirmed',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        if (approvedBookings.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No passengers yet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: approvedBookings.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final booking = approvedBookings[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.grey.shade300,
                                      child: booking.passengerProfileImage.isNotEmpty
                                          ? ClipOval(
                                              child: Image.network(
                                                booking.passengerProfileImage,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.person,
                                                    color: Colors.grey.shade600,
                                                  );
                                                },
                                              ),
                                            )
                                          : Icon(
                                              Icons.person,
                                              color: Colors.grey.shade600,
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            booking.passengerName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.event_seat,
                                                size: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${booking.seatsRequested} seat${booking.seatsRequested > 1 ? 's' : ''}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.green.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 14,
                                            color: Colors.green.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Confirmed',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 100), // Space for bottom buttons
          ],
        ),
      ),

      // Bottom Action Buttons
      bottomNavigationBar: !isOwnPost
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
                        onPressed: _handleMessage,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF49977a),
                          side: const BorderSide(
                            color: Color(0xFF49977a),
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Message',
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
                        onPressed: _getButtonAction(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isButtonDisabled()
                              ? Colors.grey.shade400
                              : const Color(0xFF49977a),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _buildButtonChild(),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDetailItem({
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

// Isolated map widget for post detail to prevent rebuilds

