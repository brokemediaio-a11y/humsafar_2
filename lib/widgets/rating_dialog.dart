import 'package:flutter/material.dart';
import '../models/rating_model.dart';
import '../models/report_model.dart';
import '../services/rating_service.dart';
import '../services/report_service.dart';
import 'report_dialog.dart';

class RatingDialog extends StatefulWidget {
  final String journeyId;
  final String userToRateId;
  final String userToRateName;
  final String currentUserId;
  final String currentUserName;
  final RatingType ratingType;
  final VoidCallback? onRatingSubmitted;

  const RatingDialog({
    super.key,
    required this.journeyId,
    required this.userToRateId,
    required this.userToRateName,
    required this.currentUserId,
    required this.currentUserName,
    required this.ratingType,
    this.onRatingSubmitted,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final RatingService _ratingService = RatingService();
  final ReportService _reportService = ReportService();
  final TextEditingController _reviewController = TextEditingController();
  
  double _rating = 0;
  bool _isSubmitting = false;
  bool _hasReported = false;

  @override
  void initState() {
    super.initState();
    _checkIfUserHasReported();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _checkIfUserHasReported() async {
    final hasReported = await _reportService.hasUserReported(
      journeyId: widget.journeyId,
      reporterId: widget.currentUserId,
      reportedUserId: widget.userToRateId,
    );
    
    if (mounted) {
      setState(() => _hasReported = hasReported);
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final rating = RatingModel(
      id: '${widget.journeyId}_${widget.currentUserId}_${widget.userToRateId}',
      journeyId: widget.journeyId,
      raterId: widget.currentUserId,
      ratedUserId: widget.userToRateId,
      raterName: widget.currentUserName,
      ratedUserName: widget.userToRateName,
      rating: _rating,
      review: _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
      createdAt: DateTime.now(),
      type: widget.ratingType,
    );

    final success = await _ratingService.submitRating(rating);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      widget.onRatingSubmitted?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating submitted successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit rating. Please try again.')),
      );
    }
  }

  Future<void> _showReportDialog() async {
    final reportType = widget.ratingType == RatingType.driver_to_passenger
        ? ReportType.driver_reporting_passenger
        : ReportType.passenger_reporting_driver;

    await showReportDialog(
      context: context,
      journeyId: widget.journeyId,
      reportedUserId: widget.userToRateId,
      reportedUserName: widget.userToRateName,
      reporterId: widget.currentUserId,
      reporterName: widget.currentUserName,
      reportType: reportType,
      onReportSubmitted: () {
        setState(() => _hasReported = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDriverRating = widget.ratingType == RatingType.driver_to_passenger;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          Icon(
            isDriverRating ? Icons.person : Icons.drive_eta,
            size: 48,
            color: const Color(0xFF49977a),
          ),
          const SizedBox(height: 8),
          Text(
            isDriverRating ? 'Rate Passenger' : 'Rate Driver',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.userToRateName,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How was your experience?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1.0),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _getRatingText(_rating),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            // Review Text Area
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write a review (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Report button
        TextButton.icon(
          onPressed: _isSubmitting || _hasReported ? null : _showReportDialog,
          icon: Icon(
            _hasReported ? Icons.check : Icons.report_problem,
            size: 16,
          ),
          label: Text(_hasReported ? 'Reported' : 'Report User'),
          style: TextButton.styleFrom(
            foregroundColor: _hasReported ? Colors.grey : Colors.red.shade600,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Skip'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitRating,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF49977a),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  String _getRatingText(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }
}

// Helper function to show rating dialog
Future<void> showRatingDialog({
  required BuildContext context,
  required String journeyId,
  required String userToRateId,
  required String userToRateName,
  required String currentUserId,
  required String currentUserName,
  required RatingType ratingType,
  VoidCallback? onRatingSubmitted,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => RatingDialog(
      journeyId: journeyId,
      userToRateId: userToRateId,
      userToRateName: userToRateName,
      currentUserId: currentUserId,
      currentUserName: currentUserName,
      ratingType: ratingType,
      onRatingSubmitted: onRatingSubmitted,
    ),
  );
}
