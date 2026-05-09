// lib/screens/auth/login_screen.dart
//
// PURPOSE: Phone number entry screen (Step 1 of OTP auth).
// User enters their Nepali phone number (+977...) and taps "Send OTP".
// On success, navigates to OTP verification (handled inline via AuthStatus).

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

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _onSendOtp() {
    if (!_formKey.currentState!.validate()) return;

    // Prefix +977 if user didn't type it
    String phone = _phoneController.text.trim();
    if (!phone.startsWith('+')) phone = '+977$phone';

    context.read<AuthProvider>().sendOtp(phone);
  }

  void _onVerifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP.')),
      );
      return;
    }
    context.read<AuthProvider>().verifyOtp(otp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // After OTP verify → navigate based on status
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

          final isOtpStep = auth.status == AuthStatus.awaitingOtp;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      isOtpStep ? 'Verify OTP' : 'Welcome to\n${AppStrings.appName}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOtpStep
                          ? AppStrings.enterOtp
                          : 'Find skilled workers near you',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 40),

                    if (!isOtpStep) ...[
                      // ── Phone number field ──
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: AppStrings.phone,
                          prefixText: '+977 ',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.trim().length < 9) {
                            return 'Enter a valid 10-digit number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _onSendOtp,
                        child: auth.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Send OTP'),
                      ),
                    ] else ...[
                      // ── OTP field ──
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Enter 6-digit OTP',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _onVerifyOtp,
                        child: auth.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Verify OTP'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => auth.clearError(),
                        child: const Text('Change phone number'),
                      ),
                    ],

                    // ── Error message ──
                    if (auth.status == AuthStatus.error &&
                        auth.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
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
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}