// lib/core/utils/distance_calculator.dart
//
// PURPOSE: Implements the Haversine formula to calculate real-world
// distance between two GPS coordinates (in kilometers).
// Used by WorkerProvider to filter & sort workers near the client.
// Algorithm referenced in the project proposal (Section 3.1).

import 'dart:math';

class DistanceCalculator {
  DistanceCalculator._();

  static const double _earthRadiusKm = 6371.0;

  /// Returns the great-circle distance in kilometers between two
  /// geographic points given as (latitude, longitude) in decimal degrees.
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    // Step 1: Convert degrees → radians
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double radLat1 = _toRadians(lat1);
    final double radLat2 = _toRadians(lat2);

    // Step 2: Haversine formula
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(radLat1) * cos(radLat2) * sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Step 3: Distance in km
    return _earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180.0;

  /// Convenience: returns a formatted string e.g. "1.3 km" or "850 m"
  static String formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }
}