// lib/providers/auth_provider.dart
//
// PURPOSE: Bridges AuthService with the UI layer using ChangeNotifier.
// Holds the current user state and exposes actions (sendOtp, verifyOtp,
// createProfile, logout). Screens listen to this via Provider.of<AuthProvider>.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

enum AuthStatus {
  initial,        // App just launched, checking auth state
  unauthenticated,// No user logged in → show splash/login
  awaitingOtp,    // OTP sent, waiting for user to enter code
  awaitingProfile,// New user – logged in but no Firestore profile yet
  authenticated,  // Fully logged in with profile
  loading,        // Any async operation in progress
  error,          // Something went wrong
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  String? _verificationId; // Stored between OTP send and verify steps

  // ─── Getters ──────────────────────────────────────────────────────────────
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isWorker => _user?.role == 'worker';

  // ─── Initialize (called in main.dart on app start) ───────────────────────

  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      _status = AuthStatus.unauthenticated;
    } else {
      final profile = await _authService.getUserProfile(currentUser.uid);
      if (profile == null) {
        _status = AuthStatus.awaitingProfile;
      } else {
        _user = profile;
        _status = AuthStatus.authenticated;
      }
    }
    notifyListeners();
  }

  // ─── Step 1: Send OTP ─────────────────────────────────────────────────────

  Future<void> sendOtp(String phoneNumber) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    await _authService.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        _verificationId = verificationId;
        _status = AuthStatus.awaitingOtp;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error;
        _status = AuthStatus.error;
        notifyListeners();
      },
    );
  }

  // ─── Step 2: Verify OTP ───────────────────────────────────────────────────

  Future<void> verifyOtp(String smsCode) async {
    if (_verificationId == null) return;

    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final user = await _authService.verifyOtp(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      if (user == null) throw Exception('Verification failed.');

      final exists = await _authService.userProfileExists(user.uid);
      if (exists) {
        _user = await _authService.getUserProfile(user.uid);
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.awaitingProfile; // New user → registration screen
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  // ─── Step 3: Create Profile (registration) ────────────────────────────────

  Future<void> createProfile({
    required String name,
    required String role, // 'client' or 'worker'
    String email = '',
  }) async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final firebaseUser = _authService.currentUser!;
      final newUser = UserModel(
        uid: firebaseUser.uid,
        name: name,
        phone: firebaseUser.phoneNumber ?? '',
        email: email,
        role: role,
        createdAt: DateTime.now(),
      );
      await _authService.createUserProfile(newUser);
      _user = newUser;
      _status = AuthStatus.authenticated;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}