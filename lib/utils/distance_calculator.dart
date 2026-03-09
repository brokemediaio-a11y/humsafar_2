import 'dart:math';

class DistanceCalculator {
  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;

    return distance;
  }

  static double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Calculate maximum price based on distance
  /// Formula: (35 * distanceKm) * 1.10 (includes 10% platform fee)
  /// Total = (distance × pricePerKm) × 1.10
  static double calculateMaxPrice(double distanceKm) {
    const double pricePerKm = 35.0;
    const double platformFeeMultiplier = 1.10; // 10% platform fee
    return (pricePerKm * distanceKm) * platformFeeMultiplier;
  }
}

