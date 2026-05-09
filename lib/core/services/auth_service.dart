// lib/core/services/auth_service.dart
//
// PURPOSE: All Firebase Authentication logic lives here.
// Screens and providers call these methods – they never touch
// FirebaseAuth directly. Keeps auth logic testable and swappable.
//
// Flow: Phone → OTP sent → OTP verified → User doc created in Firestore

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Current User ─────────────────────────────────────────────────────────

  /// The currently logged-in Firebase user (null if not logged in).
  User? get currentUser => _auth.currentUser;

  /// Stream that emits whenever auth state changes (login / logout).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Phone OTP Authentication ──────────────────────────────────────────────

  /// Step 1: Send OTP to the provided phone number.
  /// [onCodeSent] callback receives the verificationId needed for step 2.
  /// [onError] callback receives a human-readable error message.
  Future<void> sendOtp({
    required String phoneNumber,       // e.g. '+9779841000000'
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),

      // OTP sent successfully
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },

      // Automatic verification (Android SMS auto-read)
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },

      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'OTP verification failed.');
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        // Timeout – user must enter OTP manually (already handled via codeSent)
      },
    );
  }

  /// Step 2: Verify the OTP entered by the user.
  /// Returns the signed-in [User] on success, null on failure.
  Future<User?> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final UserCredential result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  // ─── User Profile in Firestore ────────────────────────────────────────────

  /// Creates a new user document in /users/{uid} after first login.
  Future<void> createUserProfile(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  /// Fetches the UserModel for the currently logged-in user.
  /// Returns null if the document does not exist yet (new user).
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── Check if profile exists (to decide: new registration vs returning) ───

  Future<bool> userProfileExists(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }
}