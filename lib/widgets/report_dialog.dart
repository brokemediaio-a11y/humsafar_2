import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

class ReportDialog extends StatefulWidget {
  final String journeyId;
  final String reportedUserId;
  final String reportedUserName;
  final String reporterId;
  final String reporterName;
  final ReportType reportType;
  final VoidCallback? onReportSubmitted;

  const ReportDialog({
    super.key,
    required this.journeyId,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.reporterId,
    required this.reporterName,
    required this.reportType,
    this.onReportSubmitted,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final ReportService _reportService = ReportService();
  final TextEditingController _descriptionController = TextEditingController();
  
  ReportReason? _selectedReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason for reporting')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final report = ReportModel(
      id: '${widget.journeyId}_${widget.reporterId}_${widget.reportedUserId}_${DateTime.now().millisecondsSinceEpoch}',
      reporterId: widget.reporterId,
      reportedUserId: widget.reportedUserId,
      reporterName: widget.reporterName,
      reportedUserName: widget.reportedUserName,
      journeyId: widget.journeyId,
      reason: _selectedReason!,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      createdAt: DateTime.now(),
      status: ReportStatus.pending,
      type: widget.reportType,
    );

    final success = await _reportService.submitReport(report);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      widget.onReportSubmitted?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully. We will review it shortly.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit report. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReportingDriver = widget.reportType == ReportType.passenger_reporting_driver;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          Icon(
            Icons.report_problem,
            size: 48,
            color: Colors.red.shade600,
          ),
          const SizedBox(height: 8),
          Text(
            isReportingDriver ? 'Report Driver' : 'Report Passenger',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.reportedUserName,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What is the reason for this report?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // Reason Selection
            ...ReportReason.values.map((reason) {
              return RadioListTile<ReportReason>(
                title: Text(
                  reason.displayName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  reason.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) => setState(() => _selectedReason = value),
                activeColor: Colors.red.shade600,
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }).toList(),
            const SizedBox(height: 20),
            // Description Text Area
            const Text(
              'Additional Details (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Provide additional context or details about the incident...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                counterStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reports are reviewed by our team. False reports may result in account restrictions.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
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
              : const Text('Submit Report'),
        ),
      ],
    );
  }
}

// Helper function to show report dialog
Future<void> showReportDialog({
  required BuildContext context,
  required String journeyId,
  required String reportedUserId,
  required String reportedUserName,
  required String reporterId,
  required String reporterName,
  required ReportType reportType,
  VoidCallback? onReportSubmitted,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ReportDialog(
      journeyId: journeyId,
      reportedUserId: reportedUserId,
      reportedUserName: reportedUserName,
      reporterId: reporterId,
      reporterName: reporterName,
      reportType: reportType,
      onReportSubmitted: onReportSubmitted,
    ),
  );
}