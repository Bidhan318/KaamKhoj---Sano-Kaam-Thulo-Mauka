// lib/providers/location_provider.dart
//
// PURPOSE: Holds the client's current GPS position and makes it available
// to all widgets. Also starts the worker location stream if the logged-in
// user is a worker (keeps their Firestore coordinates updated).

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/utils/location_helper.dart';
import '../core/services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  Position? _currentPosition;
  String _currentAddress = '';
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ──────────────────────────────────────────────────────────────
  Position? get currentPosition => _currentPosition;
  String get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLocation => _currentPosition != null;

  double get latitude => _currentPosition?.latitude ?? 0.0;
  double get longitude => _currentPosition?.longitude ?? 0.0;

  // ─── Get Client Location ──────────────────────────────────────────────────

  /// Called when the HomeScreen loads.
  /// Fetches a one-time GPS fix and reverse-geocodes it to an address.
  Future<void> fetchCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPosition = await LocationHelper.getCurrentPosition();
      _currentAddress = await LocationHelper.getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Start Worker Location Streaming ─────────────────────────────────────

  /// If the logged-in user is a worker, this starts a continuous GPS stream
  /// and pushes each new position to Firestore so their map pin moves live.
  void startWorkerLocationStream(String workerUid) {
    LocationHelper.getPositionStream().listen((Position position) async {
      _currentPosition = position;
      notifyListeners();

      // Write updated coordinates to Firestore
      await _locationService.updateWorkerLocation(
        workerUid: workerUid,
        position: position,
      );
    });
  }
}