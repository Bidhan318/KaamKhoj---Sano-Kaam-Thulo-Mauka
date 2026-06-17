// lib/screens/splash/splash_screen.dart
<<<<<<< HEAD

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
=======
//
// PURPOSE: First screen shown on app launch.
// Waits for AuthProvider to finish checking Firebase auth state,
// then routes to HomeScreen (if logged in) or LoginScreen (if not).
// Also a good place to show the app logo / branding.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
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

<<<<<<< HEAD
class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _pulseController;
  late AnimationController _logoController;
  late AnimationController _textController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();

    final auth = context.read<AuthProvider>();
    await auth.initialize();
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    _navigate(auth);
  }

  void _navigate(AuthProvider auth) {
    switch (auth.status) {
      case AuthStatus.authenticated:
        Navigator.pushReplacement(context, _fadeRoute(const HomeScreen()));
        break;
      case AuthStatus.requiresBiometricUnlock:
        Navigator.pushReplacement(context, _fadeRoute(const FingerprintLockScreen()));
        break;
      case AuthStatus.awaitingProfile:
        Navigator.pushReplacement(context, _fadeRoute(const RegisterScreen()));
        break;
      case AuthStatus.awaitingFingerprintSetup:
        Navigator.pushReplacement(context, _fadeRoute(FingerprintSetupScreen(
          email: auth.pendingEmail ?? '',
          password: auth.pendingPassword ?? '',
        )));
        break;
      default:
        Navigator.pushReplacement(context, _fadeRoute(const LoginScreen()));
    }
  }

  PageRoute _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // ── Dark navy → bright teal gradient ──
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D1B3E), // dark navy top
              Color(0xFF1A3A5C), // mid indigo
              Color(0xFF0D7377), // teal-green
              Color(0xFF14A085), // bright teal bottom
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        // ── Everything centered vertically ──
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),

            // ── Pulse rings + Logo (NO static background rings) ────────────
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 3 animated expanding pulse rings
                  _PulseRing(controller: _pulseController, maxRadius: 130, offset: 0.0),
                  _PulseRing(controller: _pulseController, maxRadius: 130, offset: 0.33),
                  _PulseRing(controller: _pulseController, maxRadius: 130, offset: 0.66),

                  // ── Glassy logo box ──────────────────────────────────────
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (_, __) => Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: Container(
                          width: 115,
                          height: 115,
                          clipBehavior: Clip.antiAlias, // clips image to rounded corners
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF14A085).withValues(alpha: 0.55),
                                blurRadius: 36,
                                spreadRadius: 6,
                              ),
                              BoxShadow(
                                color: const Color(0xFF3F51B5).withValues(alpha: 0.30),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/splash_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── App name ──────────────────────────────────────────────────
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textOpacity,
                child: Column(
                  children: [
                    // 'KaamKhoj' — pure white, very bold, large
                    Text(
                      AppStrings.appName,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Tagline — distinct light teal color (not white)
                    Text(
                      AppStrings.tagline,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF80CBC4), // light teal
                        fontSize: 15,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 2),
=======
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
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD
}

// ── Animated expanding pulse ring ─────────────────────────────────────────────
class _PulseRing extends StatelessWidget {
  final AnimationController controller;
  final double maxRadius;
  final double offset;

  const _PulseRing({
    required this.controller,
    required this.maxRadius,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = (controller.value + offset) % 1.0;
        final size = maxRadius * 2 * (0.25 + t * 0.75);
        final opacity = (1.0 - t) * 0.45;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }
=======
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
}