// lib/widgets/map_marker.dart
//
// PURPOSE: Utility for building custom flutter_map markers.
// Replaces the old Google Maps BitmapDescriptor approach.

import 'package:flutter/material.dart';

class MapMarkerHelper {
  MapMarkerHelper._();

  /// Returns a red pin icon widget for worker markers.
  static Widget workerMarker({VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: const Icon(
        Icons.location_pin,
        color: Colors.red,
        size: 40,
      ),
    );
  }

  /// Returns a blue location icon for the client/user marker.
  static Widget clientMarker() {
    return const Icon(
      Icons.my_location,
      color: Colors.blue,
      size: 32,
    );
  }

  /// Returns a circular letter marker widget (worker's initial).
  static Widget letterMarker({
    required String letter,
    Color backgroundColor = const Color(0xFF1A73E8),
    Color textColor = Colors.white,
    double size = 40,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          letter.toUpperCase(),
          style: TextStyle(
            color: textColor,
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}