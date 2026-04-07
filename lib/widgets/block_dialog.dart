import 'package:flutter/material.dart';
import '../services/block_service.dart';

class BlockDialog extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String otherUserId;
  final String otherUserName;
  final VoidCallback? onUserBlocked;

  const BlockDialog({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.otherUserId,
    required this.otherUserName,
    this.onUserBlocked,
  });

  @override
  State<BlockDialog> createState() => _BlockDialogState();
}

class _BlockDialogState extends State<BlockDialog> {
  final BlockService _blockService = BlockService();
  final TextEditingController _reasonController = TextEditingController();
  
  bool _isBlocking = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _blockUser() async {
    setState(() => _isBlocking = true);

    final success = await _blockService.blockUser(
      blockerId: widget.currentUserId,
      blockedUserId: widget.otherUserId,
      blockerName: widget.currentUserName,
      blockedUserName: widget.otherUserName,
      reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isBlocking = false);

    if (success) {
      widget.onUserBlocked?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.otherUserName} has been blocked'),
          backgroundColor: Colors.orange.shade600,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to block user. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          Icon(
            Icons.block,
            size: 48,
            color: Colors.red.shade600,
          ),
          const SizedBox(height: 8),
          const Text(
            'Block User',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.otherUserName,
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_outlined,
                    size: 20,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Blocking this user will prevent them from messaging you and you from messaging them.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reason (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Why are you blocking this user?',
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isBlocking ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isBlocking ? null : _blockUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isBlocking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Block User'),
        ),
      ],
    );
  }
}

// Helper function to show block dialog
Future<void> showBlockDialog({
  required BuildContext context,
  required String currentUserId,
  required String currentUserName,
  required String otherUserId,
  required String otherUserName,
  VoidCallback? onUserBlocked,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => BlockDialog(
      currentUserId: currentUserId,
      currentUserName: currentUserName,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      onUserBlocked: onUserBlocked,
    ),
  );
}