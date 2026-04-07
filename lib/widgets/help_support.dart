import 'package:flutter/material.dart';

void showHelpDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Need Help?'),
        content: const Text(
          'For help and support, please email connect@nexordis.com.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

class GlobalHelpButton extends StatelessWidget {
  const GlobalHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 8;

    return Positioned(
      top: topPadding,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showHelpDialog(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.help_outline, size: 18, color: Color(0xFF49977a)),
                SizedBox(width: 4),
                Text(
                  'Help',
                  style: TextStyle(
                    color: Color(0xFF49977a),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
