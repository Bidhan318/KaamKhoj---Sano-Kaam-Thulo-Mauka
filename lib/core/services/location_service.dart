// lib/core/services/location_service.dart
//
// PURPOSE: Manages real-time location updates for workers.
// When a worker opens the app, this service streams their GPS position
// and writes it to their Firestore document so clients see them on the map.
// Also fetches all worker locations for the map markers.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/worker_model.dart';
import '../utils/location_helper.dart';
import '../utils/distance_calculator.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Update Worker Location in Firestore ──────────────────────────────────

  /// Writes the worker's current GPS coordinates to /workers/{uid}.
  /// Called whenever the position stream emits a new location.
  Future<void> updateWorkerLocation({
    required String workerUid,
    required Position position,
  }) async {
    final address = await LocationHelper.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    await _firestore.collection('workers').doc(workerUid).update({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'address': address,
    });
  }

  // ─── Fetch Nearby Workers ─────────────────────────────────────────────────

  /// Fetches all available workers from Firestore, calculates their distance
  /// from [clientLat]/[clientLon], filters by [radiusKm], and sorts by distance.
  ///
  /// This implements the "Nearby Worker Search Algorithm" from Section 3.1.
  Future<List<WorkerModel>> getNearbyWorkers({
    required double clientLat,
    required double clientLon,
    double radiusKm = 5.0,
    String? skillFilter, // Optional: filter by skill type
  }) async {
    Query query = _firestore
        .collection('workers')
        .where('isAvailable', isEqualTo: true);

    final snapshot = await query.get();

    List<WorkerModel> workers = snapshot.docs
        .map((doc) => WorkerModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    // Calculate distance for each worker (Haversine)
    for (int i = 0; i < workers.length; i++) {
      final distance = DistanceCalculator.calculateDistance(
        lat1: clientLat,
        lon1: clientLon,
        lat2: workers[i].latitude,
        lon2: workers[i].longitude,
      );
      workers[i] = workers[i].copyWith(distanceFromClient: distance);
    }

    // Filter by radius
    workers = workers.where((w) => w.distanceFromClient! <= radiusKm).toList();

    // Optional skill filter
    if (skillFilter != null && skillFilter.isNotEmpty) {
      workers = workers
          .where((w) => w.skills
              .any((s) => s.toLowerCase().contains(skillFilter.toLowerCase())))
          .toList();
    }

    // Sort by nearest first
    workers.sort((a, b) =>
        (a.distanceFromClient ?? 99).compareTo(b.distanceFromClient ?? 99));

    return workers;
  }

  // ─── Real-time stream of all workers (for live map updates) ───────────────

  /// Returns a live Firestore stream of all available workers.
  /// The HomeScreen map listens to this to update markers in real time.
  Stream<List<WorkerModel>> watchNearbyWorkers({
    required double clientLat,
    required double clientLon,
    double radiusKm = 5.0,
  }) {
    return _firestore
        .collection('workers')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      List<WorkerModel> workers = snapshot.docs
          .map((doc) =>
              WorkerModel.fromMap(doc.data()))
          .toList();

      for (int i = 0; i < workers.length; i++) {
        final distance = DistanceCalculator.calculateDistance(
          lat1: clientLat,
          lon1: clientLon,
          lat2: workers[i].latitude,
          lon2: workers[i].longitude,
        );
        workers[i] = workers[i].copyWith(distanceFromClient: distance);
      }

      workers =
          workers.where((w) => w.distanceFromClient! <= radiusKm).toList();
      workers.sort((a, b) =>
          (a.distanceFromClient ?? 99).compareTo(b.distanceFromClient ?? 99));

      return workers;
    });
  }
}