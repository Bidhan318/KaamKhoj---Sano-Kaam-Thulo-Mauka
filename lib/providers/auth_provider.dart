import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/auth_service.dart';
import '../core/services/biometric_service.dart';
import '../models/user_model.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  awaitingProfile,
  awaitingFingerprintSetup,
  requiresBiometricUnlock,
  authenticated,
  loading,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService.instance;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  //temporary store for fingerprint setup
  String? _pendingEmail;
  String? _pendingPassword;

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
 
    final currentUser = _authService.currentUser;
 
    if (currentUser == null) {
      // No Firebase session — go to login
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
 
    // Firebase session is active — load profile
    final profile = await _authService.getUserProfile(currentUser.uid);
    if (profile == null) {
      _status = AuthStatus.awaitingProfile;
      notifyListeners();
      return;
    }
 
    _user = profile;
 
    // Check if we should show the fingerprint lock gate
    final biometricAvailable = await _biometricService.isBiometricAvailable();
    final biometricEnabled = await _biometricService.isBiometricEnabled();
    final savedCredentials = await _biometricService.getSavedCredentials();
 
    if (biometricAvailable && biometricEnabled && savedCredentials?.email == currentUser.email) {
      // Device has biometrics set up for this user → require fingerprint before HomeScreen
      _status = AuthStatus.requiresBiometricUnlock;
    } else {
      _status = AuthStatus.authenticated;
    }
 
    notifyListeners();
  }

  // ─── Cancel Registration ────────────────────────────────────────────────────
  /// Deletes the half-created Firebase Auth user and returns to login.
  /// Called when user taps Back on the profile-creation screen.
  Future<void> cancelRegistration() async {
    try {
      await _authService.currentUser?.delete();
    } catch (_) {
      // If delete fails (e.g. requires re-auth), just sign out instead
      await _authService.signOut();
    }
    _user = null;
    _status = AuthStatus.unauthenticated;
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
        notifyListeners();
        return;
      }
 
      _user = profile;
 
      // Check if we should offer fingerprint setup
      final biometricAvailable = await _biometricService.isBiometricAvailable();
      final biometricEnabled = await _biometricService.isBiometricEnabled();
 
      if (biometricAvailable && !biometricEnabled) {
        // First login on this device (or after a logout clears biometric)
        // → offer fingerprint setup, hold credentials temporarily
        _pendingEmail = email;
        _pendingPassword = password;
        _status = AuthStatus.awaitingFingerprintSetup;
      } else {
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

  /// Used when the user taps "Login with Fingerprint" on the login screen.
  /// Retrieves saved credentials, scans fingerprint, then signs into Firebase.
  Future<void> signInWithBiometric() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
 
    try {
      // 1. Check saved credentials exist
      final saved = await _biometricService.getSavedCredentials();
      if (saved == null) {
        _errorMessage = 'No fingerprint login saved. Please use email & password.';
        _status = AuthStatus.error;
        notifyListeners();
        return;
      }
 
      // 2. Prompt fingerprint
      final authenticated = await _biometricService.authenticate(
        reason: 'Scan your fingerprint to log in to KaamKhoj',
      );
      if (!authenticated) {
        _errorMessage = 'Fingerprint not recognised.';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }
 
      // 3. Use saved credentials to sign into Firebase
      final user = await _authService.signInWithEmail(
        email: saved.email,
        password: saved.password,
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
 
  // ─── Biometric unlock ────
  /// Used by FingerprintLockScreen. Only scans fingerprint — Firebase session
  /// is already active at this point.
  Future<bool> authenticateWithBiometric() async {
    final success = await _biometricService.authenticate(
      reason: 'Scan your fingerprint to unlock KaamKhoj',
    );
    if (success) {
      _status = AuthStatus.authenticated;
      notifyListeners();
    }
    return success;
  }
 
  // ─── Enable biometric (from FingerprintSetupScreen) ──────────────────────
 
  /// Prompts fingerprint scan, then saves the pending credentials.
  /// Returns true if the scan succeeded.
  Future<bool> enableBiometric({
    required String email,
    required String password,
  }) async {
    final authenticated = await _biometricService.authenticate(
      reason: 'Scan your fingerprint to enable fingerprint login',
    );
 
    if (authenticated) {
      await _biometricService.saveCredentials(
        email: email,
        password: password,
      );
      _clearPendingCredentials();
      _status = AuthStatus.authenticated;
      notifyListeners();
    }
 
    return authenticated;
  }
 
  /// Called when user taps "Skip" on FingerprintSetupScreen.
  void skipBiometricSetup() {
    _clearPendingCredentials();
    _status = AuthStatus.authenticated;
    notifyListeners();
  }
 
  void _clearPendingCredentials() {
    _pendingEmail = null;
    _pendingPassword = null;
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
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
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

  String? get pendingEmail => _pendingEmail;
  String? get pendingPassword => _pendingPassword;
}
