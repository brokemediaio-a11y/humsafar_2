import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart';
import '../screens/post_detail_screen.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onRequestSeat;
  final VoidCallback? onOfferRide;
  final VoidCallback? onMessage;

  const PostCard({
    super.key,
    required this.post,
    this.onRequestSeat,
    this.onOfferRide,
    this.onMessage,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();
  bool _hasPendingRequest = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPendingRequest();
  }

  Future<void> _checkPendingRequest() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || widget.post.type != PostType.driver) {
      setState(() => _isLoading = false);
      return;
    }

    final hasPending = await _bookingService.hasPendingRequest(
      currentUser.uid,
      widget.post.id,
    );
    
    if (mounted) {
      setState(() {
        _hasPendingRequest = hasPending;
        _isLoading = false;
      });
    }
  }

  String _getCarInfo() {
    final parts = <String>[];
    if (widget.post.carMake != null && widget.post.carMake!.isNotEmpty) parts.add(widget.post.carMake!);
    if (widget.post.carModel != null && widget.post.carModel!.isNotEmpty) parts.add(widget.post.carModel!);
    if (widget.post.carColor != null && widget.post.carColor!.isNotEmpty) parts.add(widget.post.carColor!);
    return parts.join(' • ');
  }

  bool _hasCarInfo() {
    return (widget.post.carMake != null && widget.post.carMake!.isNotEmpty) ||
           (widget.post.carModel != null && widget.post.carModel!.isNotEmpty) ||
           (widget.post.carColor != null && widget.post.carColor!.isNotEmpty);
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
        ? widget.onRequestSeat
        : widget.onOfferRide;
  }

  Widget _buildButtonChild() {
    if (_isLoading && widget.post.type == PostType.driver) {
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
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to post detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: widget.post),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Profile section
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade300,
                  child: widget.post.userProfileImageUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            widget.post.userProfileImageUrl,
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.post.userName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.post.isVerified) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
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
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 10,
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
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.post.type == PostType.driver ? 'Driver' : 'Passenger',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Route details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF49977a),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF49977a).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF49977a),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From ${widget.post.fromLocation}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'To ${widget.post.toLocation}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.post.departureTime != null)
                      Text(
                        'Departs ${_formatTime(widget.post.departureTime!)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    if (widget.post.timeWindow != null)
                      Text(
                        'Window ${widget.post.timeWindow}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    if (widget.post.price != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Price Rs. ${widget.post.price}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF49977a),
                        ),
                      ),
                    ],
                    if (widget.post.etaMinutes != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'ETA ${widget.post.etaMinutes} min',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Ride details
            Row(
              children: [
                // Seats info
                if (widget.post.seatsAvailable != null)
                  Expanded(
                    child: _InfoBox(
                      label: 'Seats',
                      value: '${widget.post.seatsAvailable} available',
                    ),
                  ),
                if (widget.post.seatsNeeded != null)
                  Expanded(
                    child: _InfoBox(
                      label: 'Seats',
                      value: '${widget.post.seatsNeeded} needed',
                    ),
                  ),
                // Car info - only show for driver posts
                if (widget.post.type == PostType.driver && _hasCarInfo()) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoBox(
                      label: 'Car',
                      value: _getCarInfo(),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _getButtonAction(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isButtonDisabled() 
                          ? Colors.grey.shade400 
                          : const Color(0xFF49977a),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _buildButtonChild(),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: widget.onMessage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF49977a),
                    side: const BorderSide(color: Color(0xFF49977a)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Message',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
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
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF49977a),
            ),
          ),
        ],
      ),
    );
  }
}

