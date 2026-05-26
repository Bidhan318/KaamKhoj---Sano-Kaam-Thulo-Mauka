import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService{
  BiometricService._();
  static final BiometricService instance = BiometricService._();
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _kBiometricEnabled = 'biometric_enabled';
  static const String _kStoredEmail = 'stored_email';
  static const String _kStoredPassword = 'stored_password';

  //---Device Capability Check---
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final available = await _localAuth.getAvailableBiometrics();
      if (!canCheck || !isDeviceSupported) return false;
 
      
      print('canCheck: $canCheck');
      print('isDeviceSupported: $isDeviceSupported');
      print('available: $available');  // ← shows what biometrics are found
      return available.isNotEmpty;
    } on PlatformException catch (e) {
      print('biometric error: $e'); 
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricEnabled) ?? false;
  }

  //-Authenticate User---

  Future<bool> authenticate({String reason = 'Verify your identity to continue'}) async {
    try {
      final result = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,   // don't fall back to PIN/pattern
          stickyAuth: true,      // keep prompt alive if app goes to background
        ),
      );
      print('authenticate result: $result');  // ← add this
      return result;
    } on PlatformException catch (e) {
      print('authenticate error code: ${e.code}');    // ← add this
    print('authenticate error msg: ${e.message}');  // ← add this
      return false;
    }
  }

   // ─── Save credentials (called after successful email/password login) ────────
 
  /// Stores email + password so fingerprint can replay the login later.
  /// Call this ONLY after Firebase has confirmed the credentials are valid.
  Future<void> saveCredentials({   //whats shared prerferneces and how it  works1:59 PMClaude responded: SharedPreferences is a simple key-value storage that
                                  //  saves small pieces of data permanently on the device — survives app restarts and closing.SharedPreferences is a simple key-value storage 
                                    //that saves small pieces of data permanently on the device — survives app restarts and closing.
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_kStoredEmail, email);
    await prefs.setString(_kStoredPassword, password);
    await prefs.setBool(_kBiometricEnabled, true);
  }
  //retrieve saved info
  Future<({String email, String password})?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_kStoredEmail);
    final password = prefs.getString(_kStoredPassword);
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  //clear on logout
  Future<void> clearCredentials() async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kStoredEmail);
    await prefs.remove(_kStoredPassword);
    await prefs.setBool(_kBiometricEnabled, false);
  }
}

 

