// lib/core/utils/location_helper.dart
//
// PURPOSE: Helper functions for location permission checks.
// Geocoding (address lookup) replaced with OpenStreetMap Nominatim API
// which is free and requires no API key.

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationHelper {
  LocationHelper._();

  /// Requests location permission and returns the current Position.
  /// Throws a descriptive exception if permission is denied.
  static Future<Position> getCurrentPosition() async {
    if (kIsWeb) {
      // On web, geolocator works but permission handling is browser-native
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. '
        'Please enable it in app settings.',
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Converts GPS coordinates to a human-readable address string
  /// using OpenStreetMap Nominatim (free, no API key needed).
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$latitude&lon=$longitude&format=json',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'KaamKhojApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];
        final parts = [
          address['suburb'],
          address['city'] ?? address['town'] ?? address['village'],
          address['state'],
        ].where((p) => p != null && (p as String).isNotEmpty).toList();
        return parts.join(', ');
      }
    } catch (_) {}
    return '';
  }

  /// Returns a Geolocator stream so providers can react to live movement.
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    );
  }
}