// lib/screens/auth/login_screen.dart
//
// PURPOSE: Email + Password auth screen.
// Has two tabs: Sign In (existing user) and Register (new user).
// 100% free — no SMS, no billing needed.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmController.dispose();
    super.dispose();
  }

  void _onSignIn(AuthProvider auth) {
    if (!_signInFormKey.currentState!.validate()) return;
    auth.signIn(
      email: _signInEmailController.text.trim(),
      password: _signInPasswordController.text,
    );
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
          // Navigate after auth state changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (auth.status == AuthStatus.authenticated) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            } else if (auth.status == AuthStatus.awaitingProfile) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            }
          });

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
            ),
          );
        },
      ),
    );
  }

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
            _buildErrorBox(auth),
          ],
        ),
      ),
    );
  }

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
    );
  }

  Widget _buildErrorBox(AuthProvider auth) {
    if (auth.status != AuthStatus.error || auth.errorMessage == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              auth.errorMessage!,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}