// PURPOSE: Gate screen shown when the app reopens with an active Firebase
// session AND biometric is enabled on this device.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import '../auth/login_screen.dart';

class FingerprintLockScreen extends StatefulWidget {
  const FingerprintLockScreen({super.key});

  @override
  State<FingerprintLockScreen> createState() => _FingerprintLockScreenState();
}

class _FingerprintLockScreenState extends State<FingerprintLockScreen>
    with SingleTickerProviderStateMixin {

  bool _isAuthenticating = false;
  String? _errorMessage;

  late AnimationController _enterController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterController, curve: Curves.easeOut));

    _enterController.forward();

    // Start biometric auth after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }
  
  Future<void> _authenticate() async{
    setState((){
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.authenticateWithBiometric(); //calls biometric service to authenticate with fingerprint

    if (!mounted) return;
      setState(() => _isAuthenticating = false);
 
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() => _errorMessage = 'Fingerprint not recognised. Try again.');
      }
  }

  Future<void> _usePasswordInstead() async {
    // Sign out Firebase so user goes through full email/pass flow again
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8EAF6), // very light lavender
              Colors.white,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    // ── Geometric Logo (same as login, enlarged) ──
                    CustomPaint(
                      size: const Size(160, 160),
                      painter: _GeometricLogoPainter(),
                    ),

                    const SizedBox(height: 48),

                    // ── Title ──
                    Text(
                      AppStrings.welcomeBack,
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A1A2C),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // ── Subtitle (Tap/Touch fingerprint line, enlarged) ──
                    Text(
                      _isAuthenticating
                          ? 'Scanning fingerprint...'
                          : 'Touch the fingerprint sensor to unlock',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // ── Error message ──
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(flex: 3),

                    // ── Try Again gradient button ──
                    _buildGradientButton(
                      text: 'Try Again',
                      icon: Icons.fingerprint,
                      isLoading: _isAuthenticating,
                      onPressed: _authenticate,
                    ),

                    const SizedBox(height: 20),

                    // ── Use Password Instead ──
                    GestureDetector(
                      onTap: _isAuthenticating ? null : _usePasswordInstead,
                      child: Text(
                        'Use Password Instead',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0D7377),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required IconData icon,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) => setState(() => isPressed = false),
          onTapCancel: () => setState(() => isPressed = false),
          onTap: isLoading ? null : onPressed,
          child: AnimatedScale(
            scale: isPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2E3F80), // indigo
                    Color(0xFF14A085), // teal
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF14A085).withValues(alpha: 0.35),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            text,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Geometric Logo Painter (exact copy from login_screen.dart) ──────────────
class _GeometricLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Navy Top-Left Donut Quadrant
    final navyPaint = Paint()..color = const Color(0xFF232D59)..style = PaintingStyle.fill;
    final navyDonutPath = Path();
    navyDonutPath.moveTo(0, h/2);
    navyDonutPath.arcToPoint(Offset(w/2, 0), radius: Radius.circular(w/2), clockwise: true);
    navyDonutPath.lineTo(w/2, h/4);
    navyDonutPath.arcToPoint(Offset(w/4, h/2), radius: Radius.circular(w/4), clockwise: false);
    navyDonutPath.close();
    canvas.drawPath(navyDonutPath, navyPaint);

    // 2. Navy Bottom-Left Triangle
    final navyTrianglePath = Path();
    navyTrianglePath.moveTo(0, h/2);
    navyTrianglePath.lineTo(0, h);
    navyTrianglePath.lineTo(w/2, h);
    navyTrianglePath.close();
    canvas.drawPath(navyTrianglePath, navyPaint);

    // 3. Teal Triangle
    final tealPaint = Paint()..color = const Color(0xFF14A085)..style = PaintingStyle.fill;
    final tealPath = Path();
    tealPath.moveTo(0, h/2);
    tealPath.lineTo(w/2, h/2);
    tealPath.lineTo(w/2, h);
    tealPath.close();
    canvas.drawPath(tealPath, tealPaint);

    // 4. Blue Center Semi-Circle (Right-facing)
    final bluePaint = Paint()..color = const Color(0xFF1A5C80)..style = PaintingStyle.fill;
    final bluePath = Path();
    bluePath.moveTo(w/2, h/4);
    bluePath.arcToPoint(Offset(w/2, 3*h/4), radius: Radius.circular(w/4), clockwise: true);
    bluePath.close();
    canvas.drawPath(bluePath, bluePaint);

    // 5. Amber Circle (Top Right with gap)
    final amberPaint = Paint()..color = const Color(0xFFFFB74D)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.75, h * 0.15), w * 0.14, amberPaint);

    // 6. Orange Bottom-Right (Top-Left Quadrant shape with gap)
    final orangePaint = Paint()..color = const Color(0xFFF6A841)..style = PaintingStyle.fill;
    final orangePath = Path();
    orangePath.moveTo(w, h);
    orangePath.lineTo(w - w*0.44, h);
    orangePath.arcToPoint(Offset(w, h - w*0.44), radius: Radius.circular(w*0.44), clockwise: true);
    orangePath.close();
    canvas.drawPath(orangePath, orangePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
