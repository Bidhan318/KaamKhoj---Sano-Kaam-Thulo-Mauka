// lib/core/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/worker_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Email Auth ────────────────────────────────────────────────────────────
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<User?> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ─── User Profile ──────────────────────────────────────────────────────────
  Future<void> createUserProfile(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<bool> userProfileExists(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  // ─── Worker Profile ────────────────────────────────────────────────────────
  /// Creates a worker document in /workers/{uid} automatically on registration.
  /// Location starts at 0,0 and gets updated live when the worker opens the app.
  Future<void> createWorkerProfile({
    required String uid,
    required String name,
    required String email,
    required String skill,
    required double ratePerDay,
  }) async {
    final workerData = WorkerModel(
      uid: uid,
      name: name,
      phone: email, // using email as identifier since we switched from phone
      skills: [skill],
      ratePerDay: ratePerDay,
      latitude: 0.0,  // will be updated when worker opens the app
      longitude: 0.0,
      isAvailable: true,
      rating: 0.0,
      totalReviews: 0,
      address: '',
    );

    await _firestore
        .collection('workers')
        .doc(uid)
        .set(workerData.toMap(), SetOptions(merge: true));
  }

  // ─── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }
}