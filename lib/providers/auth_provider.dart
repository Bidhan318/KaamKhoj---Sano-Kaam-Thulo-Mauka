import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  awaitingProfile,
  authenticated,
  loading,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isWorker => _user?.role == 'worker';

  // ─── Initialize ────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final currentUser = _authService.currentUser;  //checks with firebase (auth_service.dart) for if someone is already logged in 
    if (currentUser == null) {
      _status = AuthStatus.unauthenticated;
    } else {
      final profile = await _authService.getUserProfile(currentUser.uid); //gets logged in users profile from firebase /users collection
      if (profile == null) {
        _status = AuthStatus.awaitingProfile;
      } else {
        _user = profile;
        _status = AuthStatus.authenticated;
      }
    }
    notifyListeners();
  }

  // ─── Sign In ───────────────────────────────────────────────────────────────
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
 
    try {
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      if (user == null) throw Exception('Sign in failed.');

      final profile = await _authService.getUserProfile(user.uid);
      if (profile == null) {
        _status = AuthStatus.awaitingProfile;
      } else {
        _user = profile;
        _status = AuthStatus.authenticated;
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = _friendlyError(e.code);
      _status = AuthStatus.error;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  // ─── Register ──────────────────────────────────────────────────────────────
  Future<void> register({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.registerWithEmail(
        email: email,
        password: password,
      );
      if (user == null) throw Exception('Registration failed.');
      _status = AuthStatus.awaitingProfile;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _friendlyError(e.code);
      _status = AuthStatus.error;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  // ─── Create Profile ────────────────────────────────────────────────────────
  /// Called from RegisterScreen after role/name/skill selection.
  /// For workers: also creates a /workers/{uid} document automatically.
  Future<void> createProfile({
    required String name,
    required String role,
    String? skill,
    double? ratePerDay,
  }) async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final firebaseUser = _authService.currentUser!;

      // 1. Create user profile in /users collection
      final newUser = UserModel(
        uid: firebaseUser.uid,
        name: name,
        phone: '',
        email: firebaseUser.email ?? '',
        role: role,
        createdAt: DateTime.now(),
      );
      await _authService.createUserProfile(newUser);

      // 2. If worker — also create /workers document automatically
      if (role == 'worker' && skill != null && ratePerDay != null) {
        await _authService.createWorkerProfile(
          uid: firebaseUser.uid,
          name: name,
          email: firebaseUser.email ?? '',
          skill: skill,
          ratePerDay: ratePerDay,
        );
      }

      _user = newUser;
      _status = AuthStatus.authenticated;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  // ─── Password Reset ────────────────────────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordReset(email);
  }

  // ─── Sign Out ──────────────────────────────────────────────────────────────
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

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. Please register first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}