// lib/providers/worker_provider.dart
//
// PURPOSE: Fetches, filters, and holds the list of nearby workers.
// Also manages a worker's own profile (for users with role='worker').
// The HomeScreen and WorkerListScreen consume this provider.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/location_service.dart';
import '../models/worker_model.dart';

class WorkerProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<WorkerModel> _nearbyWorkers = [];
  WorkerModel? _selectedWorker;     // Tapped on map or list
  WorkerModel? _myWorkerProfile;    // The logged-in worker's own profile
  bool _isLoading = false;
  String? _errorMessage;
  double _searchRadius = 5.0;       // km, user can change this
  String _skillFilter = '';

  // ─── Getters ──────────────────────────────────────────────────────────────
  List<WorkerModel> get nearbyWorkers => _nearbyWorkers;
  WorkerModel? get selectedWorker => _selectedWorker;
  WorkerModel? get myWorkerProfile => _myWorkerProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get searchRadius => _searchRadius;
  String get skillFilter => _skillFilter;

  // ─── Fetch Nearby Workers ─────────────────────────────────────────────────

  Future<void> fetchNearbyWorkers({
    required double clientLat,
    required double clientLon,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _nearbyWorkers = await _locationService.getNearbyWorkers(
        clientLat: clientLat,
        clientLon: clientLon,
        radiusKm: _searchRadius,
        skillFilter: _skillFilter.isEmpty ? null : _skillFilter,
      );
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Live Stream of Nearby Workers (for map markers) ─────────────────────

  Stream<List<WorkerModel>> watchNearbyWorkers({
    required double clientLat,
    required double clientLon,
    double? radiusKm,
  }) {
    return _locationService.watchNearbyWorkers(
      clientLat: clientLat,
      clientLon: clientLon,
      radiusKm: radiusKm ?? _searchRadius,
    );
  }

  // ─── Select a Worker (from map tap or list tap) ───────────────────────────

  void selectWorker(WorkerModel worker) {
    _selectedWorker = worker;
    notifyListeners();
  }

  void clearSelection() {
    _selectedWorker = null;
    notifyListeners();
  }

  // ─── Filters ──────────────────────────────────────────────────────────────

  void setSearchRadius(double km) {
    _searchRadius = km;
    notifyListeners();
  }

  void setSkillFilter(String skill) {
    _skillFilter = skill;
    notifyListeners();
  }

  // ─── Worker's Own Profile Management ─────────────────────────────────────

  /// Loads the logged-in worker's profile from /workers/{uid}.
  Future<void> loadMyWorkerProfile(String uid) async {
    final doc = await _firestore.collection('workers').doc(uid).get();
    if (doc.exists) {
      _myWorkerProfile = WorkerModel.fromMap(doc.data()!);
      notifyListeners();
    }
  }

  /// Creates or updates the worker's profile in Firestore.
  Future<void> saveWorkerProfile(WorkerModel profile) async {
    await _firestore
        .collection('workers')
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));

    // Sync profileImage and name to UserModel
    await _firestore
        .collection('users')
        .doc(profile.uid)
        .set({
          'profileImage': profile.profileImage,
          'name': profile.name,
        }, SetOptions(merge: true));

    _myWorkerProfile = profile;
    notifyListeners();
  }

  /// Toggles the worker's availability status.
  Future<void> toggleAvailability(String uid) async {
    if (_myWorkerProfile == null) return;
    final newStatus = !_myWorkerProfile!.isAvailable;
    await _firestore.collection('workers').doc(uid).update({
      'isAvailable': newStatus,
    });
    _myWorkerProfile = _myWorkerProfile!.copyWith(isAvailable: newStatus);
    notifyListeners();
  }
}