// lib/core/services/auth_service.dart
//
// PURPOSE: All Firebase Authentication logic using Email + Password.
// Free, no billing needed, works on Android and Web.
// Flow: Enter email + password → logged in → profile created in Firestore

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Current User ──────────────────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Sign In with Email + Password ────────────────────────────────────────
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

  // ─── Register with Email + Password ───────────────────────────────────────
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

  // ─── Password Reset ────────────────────────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ─── User Profile in Firestore ─────────────────────────────────────────────
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

  // ─── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }
}