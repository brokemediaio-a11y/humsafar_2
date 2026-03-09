import 'package:flutter/material.dart';

/// Simple route preview widget that doesn't require Google Maps API
/// Use this if you don't want to enable billing for Google Maps Static API
class SimpleRoutePreview extends StatelessWidget {
  final String fromLocation;
  final String toLocation;
  final double? distanceKm;

  const SimpleRoutePreview({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF49977a).withValues(alpha: 0.1),
            const Color(0xFF49977a).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF49977a).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Route icon and title
            Row(
              children: [
                Icon(
                  Icons.route,
                  size: 20,
                  color: const Color(0xFF49977a),
                ),
                const SizedBox(width: 8),
                Text(
                  'Route Preview',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF49977a),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // From location
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fromLocation.length > 35
                        ? '${fromLocation.substring(0, 35)}...'
                        : fromLocation,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Connecting line
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Container(
                width: 2,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF49977a).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // To location and distance
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    toLocation.length > 35
                        ? '${toLocation.substring(0, 35)}...'
                        : toLocation,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (distanceKm != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF49977a).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${distanceKm!.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF49977a),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

