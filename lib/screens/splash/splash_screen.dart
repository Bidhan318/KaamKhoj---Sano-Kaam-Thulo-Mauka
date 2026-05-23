// lib/screens/splash/splash_screen.dart
//
// PURPOSE: First screen shown on app launch.
// Waits for AuthProvider to finish checking Firebase auth state,
// then routes to HomeScreen (if logged in) or LoginScreen (if not).
// Also a good place to show the app logo / branding.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../auth/fingerprint_setup_screen.dart';
import '../auth/fingerprint_lock_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize auth state check after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.initialize(); //checks firebase for if someone is already logged in to directly open app elsee goes to login screeen

    if (!mounted) return; //safety check for if widgets are gone by the time this async function finishes then close the func

    switch (auth.status) {
      case AuthStatus.authenticated:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
 
      case AuthStatus.requiresBiometricUnlock:
        // Active Firebase session but need fingerprint gate
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FingerprintLockScreen()),
        );
        break;
 
      case AuthStatus.awaitingProfile:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        );
        break;
 
      case AuthStatus.awaitingFingerprintSetup:
        // Shouldn't normally hit this from splash (it happens post-login)
        // but handle it defensively
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FingerprintSetupScreen(
              email: auth.pendingEmail ?? '',
              password: auth.pendingPassword ?? '',
            ),
          ),
        );
        break;
 
      default:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             // App icon placeholder – replace with actual asset
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              AppStrings.appName,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.tagline,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}