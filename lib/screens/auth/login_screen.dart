// lib/screens/auth/login_screen.dart
//
// PURPOSE: Email + Password auth screen.
// Has two views: Sign In (existing user) and Register (new user), toggled seamlessly.


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/biometric_service.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import 'fingerprint_setup_screen.dart';
import '../home/home_screen.dart';
 
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  
  bool _isLogin = true; // true = Sign In, false = Register

  // Sign In controllers
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final _signInFormKey = GlobalKey<FormState>();
  
  // Register controllers
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmController = TextEditingController();
  final _registerFormKey = GlobalKey<FormState>();

  bool _signInPasswordVisible = false;
  bool _registerPasswordVisible = false;

   // Biometric availability — loaded once on initState
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  late AnimationController _enterController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
    
    _enterController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 600)
    );
    _fadeAnimation = CurvedAnimation(
      parent: _enterController, 
      curve: Curves.easeOut
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05), 
      end: Offset.zero
    ).animate(CurvedAnimation(parent: _enterController, curve: Curves.easeOut));
    
    _enterController.forward();
  }
  
  Future<void> _loadBiometricState() async {
    final svc = BiometricService.instance;
    final available = await svc.isBiometricAvailable();
    final enabled = await svc.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  @override
  void dispose() {
    _enterController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmController.dispose();
    super.dispose();
  }
  
  void _toggleView() {
    _enterController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _isLogin = !_isLogin;
      });
      context.read<AuthProvider>().clearError();
      _enterController.forward();
    });
  }

  void _handleAuthStatus(AuthProvider auth) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (auth.status) {
        case AuthStatus.authenticated:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
          break;
        case AuthStatus.awaitingFingerprintSetup:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => FingerprintSetupScreen(
                email: auth.pendingEmail ?? _signInEmailController.text.trim(),
                password: auth.pendingPassword ?? _signInPasswordController.text,
              ),
            ),
          );
          break;
        case AuthStatus.awaitingProfile:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          );
          break;
        default:
          break;
      }
    });
  }

  void _onSignIn(AuthProvider auth) {
    if (!_signInFormKey.currentState!.validate()) return;
    auth.signIn(
      email: _signInEmailController.text.trim(),
      password: _signInPasswordController.text,
    );
  }

  void _onFingerprintLogin(AuthProvider auth) {
    auth.signInWithBiometric();
  }

  void _onRegister(AuthProvider auth) {
    if (!_registerFormKey.currentState!.validate()) return;
    auth.register(
      email: _registerEmailController.text.trim(),
      password: _registerPasswordController.text,
    );
  }

  void _onForgotPassword(AuthProvider auth) async {
    final email = _signInEmailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first, then tap Forgot Password.')),
      );
      return;
    }
    await auth.sendPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password reset email sent to $email')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          _handleAuthStatus(auth);
          return Container(
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _isLogin ? _buildSignInForm(auth) : _buildRegisterForm(auth),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSignInForm(AuthProvider auth) {
    return Form(
      key: _signInFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          // Geometric Logo
          CustomPaint(
            size: const Size(130, 130),
            painter: _GeometricLogoPainter(),
          ),
          const SizedBox(height: 32),
          Text(
            AppStrings.welcomeBack,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1A2C), // dark navy
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.signInToContinue,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          
          // Email Field
          _buildTextField(
            controller: _signInEmailController,
            label: AppStrings.emailRequired,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your email';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Password Field
          _buildTextField(
            controller: _signInPasswordController,
            label: AppStrings.password,
            icon: Icons.lock_outline,
            obscureText: !_signInPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(_signInPasswordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
              onPressed: () => setState(() => _signInPasswordVisible = !_signInPasswordVisible),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your password';
              return null;
            },
          ),
          
          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _onForgotPassword(auth),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                AppStrings.forgotPassword,
                style: TextStyle(
                  color: Color(0xFF0D7377), 
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Gradient Sign In Button
          _buildPrimaryButton(
            text: AppStrings.signIn,
            isLoading: auth.isLoading,
            onPressed: () => _onSignIn(auth),
          ),
          
          if (_biometricAvailable && _biometricEnabled) ...[
            const SizedBox(height: 36),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    AppStrings.orSignInWith,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 28),
            // Fingerprint button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: -2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: IconButton(
                iconSize: 34,
                padding: const EdgeInsets.all(18),
                color: const Color(0xFF2E3F80),
                icon: const Icon(Icons.fingerprint),
                onPressed: auth.isLoading ? null : () => _onFingerprintLogin(auth),
              ),
            ),
          ],
          
          if (_biometricAvailable && !_biometricEnabled) ...[
            const SizedBox(height: 24),
            Text(
              AppStrings.setupFingerprint,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],

          _buildErrorBox(auth),
          
          const SizedBox(height: 36),
          
          // Toggle Register
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(AppStrings.dontHaveAccount, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              GestureDetector(
                onTap: _toggleView,
                child: const Text(
                  AppStrings.register,
                  style: TextStyle(
                    color: Color(0xFF0D7377),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(AuthProvider auth) {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          // Geometric Logo
          CustomPaint(
            size: const Size(130, 130),
            painter: _GeometricLogoPainter(),
          ),
          const SizedBox(height: 32),
          Text(
            AppStrings.createAccount,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1A2C), // dark navy
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.joinKaamKhojToday,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          
          // Email Field
          _buildTextField(
            controller: _registerEmailController,
            label: AppStrings.emailRequired,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your email';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Password Field
          _buildTextField(
            controller: _registerPasswordController,
            label: AppStrings.password,
            icon: Icons.lock_outline,
            obscureText: !_registerPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(_registerPasswordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
              onPressed: () => setState(() => _registerPasswordVisible = !_registerPasswordVisible),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter a password';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Confirm Password Field
          _buildTextField(
            controller: _registerConfirmController,
            label: AppStrings.confirmPassword,
            icon: Icons.lock_outline,
            obscureText: true,
            validator: (v) {
              if (v != _registerPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 32),
          
          // Gradient Sign Up Button
          _buildPrimaryButton(
            text: AppStrings.createAccount,
            isLoading: auth.isLoading,
            onPressed: () => _onRegister(auth),
          ),
          
          _buildErrorBox(auth),
          
          const SizedBox(height: 36),
          
          // Toggle Sign In
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(AppStrings.alreadyHaveAccount, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              GestureDetector(
                onTap: _toggleView,
                child: const Text(
                  AppStrings.signIn,
                  style: TextStyle(
                    color: Color(0xFF0D7377),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    // AnimatedScale wrapper for native press effect
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        text,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildErrorBox(AuthProvider auth) {
    if (auth.status != AuthStatus.error || auth.errorMessage == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              auth.errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeometricLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Navy Top-Left Donut Quadrant
    final navyPaint = Paint()..color = const Color(0xFF232D59)..style = PaintingStyle.fill;
    final navyDonutPath = Path();
    navyDonutPath.moveTo(0, h/2);
    // Outer arc from left to top
    navyDonutPath.arcToPoint(Offset(w/2, 0), radius: Radius.circular(w/2), clockwise: true);
    // Line to inner top
    navyDonutPath.lineTo(w/2, h/4);
    // Inner arc from top back to left (counter-clockwise)
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
    // Arc to bottom, clockwise (covers the right side)
    bluePath.arcToPoint(Offset(w/2, 3*h/4), radius: Radius.circular(w/4), clockwise: true);
    bluePath.close(); // straight vertical line on the left
    canvas.drawPath(bluePath, bluePaint);

    // 5. Amber Circle (Top Right with gap)
    final amberPaint = Paint()..color = const Color(0xFFFFB74D)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.75, h * 0.15), w * 0.14, amberPaint);

    // 6. Orange Bottom-Right (Top-Left Quadrant shape with gap)
    final orangePaint = Paint()..color = const Color(0xFFF6A841)..style = PaintingStyle.fill;
    final orangePath = Path();
    orangePath.moveTo(w, h);
    orangePath.lineTo(w - w*0.44, h);
    // Arc curving up and right
    orangePath.arcToPoint(Offset(w, h - w*0.44), radius: Radius.circular(w*0.44), clockwise: true);
    orangePath.close();
    canvas.drawPath(orangePath, orangePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}