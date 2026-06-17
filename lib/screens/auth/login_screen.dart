// lib/screens/auth/login_screen.dart
//
// PURPOSE: Email + Password auth screen.
<<<<<<< HEAD
// Has two views: Sign In (existing user) and Register (new user), toggled seamlessly.


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
=======
// Has two tabs: Sign In (existing user) and Register (new user).


import 'package:flutter/material.dart';
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
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
<<<<<<< HEAD
  
  bool _isLogin = true; // true = Sign In, false = Register
=======
  late TabController _tabController;
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630

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

<<<<<<< HEAD
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
  
=======
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBiometricState();
  }
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
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
<<<<<<< HEAD
    _enterController.dispose();
=======
    _tabController.dispose();
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmController.dispose();
    super.dispose();
  }
  
<<<<<<< HEAD
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

=======
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
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
<<<<<<< HEAD
    if (!_signInFormKey.currentState!.validate()) return;
=======
    if (!_signInFormKey.currentState!.validate()) return;  //checks if all forms fields are filled correctly
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
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
<<<<<<< HEAD
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
=======
      body: Consumer<AuthProvider>(  //wheneever data for AuthProvider changes, update ui
        builder: (context, auth, _) {
          // Navigate after auth state changes
         _handleAuthStatus(auth);
          return SafeArea(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to\n${AppStrings.appName}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find skilled workers near you',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // ── Tabs ──────────────────────────────────────────────────────
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Register'),
                  ],
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  onTap: (_) => auth.clearError(),
                ),

                // ── Tab Content ───────────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSignInTab(auth),
                      _buildRegisterTab(auth),
                    ],
                  ),
                ),
              ],
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
            ),
          );
        },
      ),
    );
  }

<<<<<<< HEAD
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
=======
  // ── Sign In Tab ─────────────────────────────────────────────────────────────
  Widget _buildSignInTab(AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Form(
        key: _signInFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _signInEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _signInPasswordController,
              obscureText: !_signInPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_signInPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(
                      () => _signInPasswordVisible = !_signInPasswordVisible),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your password';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _onForgotPassword(auth),
                child: const Text('Forgot Password?'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : () => _onSignIn(auth),
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Sign In'),
              ),
            ),
 
            // ── Fingerprint login button ──
            // Shown only when the user has previously saved credentials
            if (_biometricAvailable && _biometricEnabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      auth.isLoading ? null : () => _onFingerprintLogin(auth),
                  icon: const Icon(Icons.fingerprint, size: 22),
                  label: const Text('Login with Fingerprint'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
 
            // ── Fingerprint available but not yet set up ──
            // Subtle hint so users know it's possible
            if (_biometricAvailable && !_biometricEnabled) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fingerprint,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Sign in to set up fingerprint login',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
            _buildErrorBox(auth),
          ],
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
        ),
      ),
    );
  }

<<<<<<< HEAD
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
=======
  // ── Register Tab ────────────────────────────────────────────────────────────
  Widget _buildRegisterTab(AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Form(
        key: _registerFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _registerEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registerPasswordController,
              obscureText: !_registerPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                hintText: 'At least 6 characters',
                suffixIcon: IconButton(
                  icon: Icon(_registerPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(() =>
                      _registerPasswordVisible = !_registerPasswordVisible),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter a password';
                if (v.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registerConfirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) {
                if (v != _registerPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : () => _onRegister(auth),
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Create Account'),
              ),
            ),
            _buildErrorBox(auth),
          ],
        ),
      ),
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
    );
  }

  Widget _buildErrorBox(AuthProvider auth) {
    if (auth.status != AuthStatus.error || auth.errorMessage == null) {
      return const SizedBox.shrink();
    }
    return Container(
<<<<<<< HEAD
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
=======
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              auth.errorMessage!,
<<<<<<< HEAD
              style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
=======
              style: const TextStyle(color: AppColors.error),
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
            ),
          ),
        ],
      ),
    );
  }
<<<<<<< HEAD
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
=======
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
}