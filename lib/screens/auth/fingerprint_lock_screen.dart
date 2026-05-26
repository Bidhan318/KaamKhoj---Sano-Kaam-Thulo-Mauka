// PURPOSE: Gate screen shown when the app reopens with an active Firebase
// session AND biometric is enabled on this device.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import '../auth/login_screen.dart';

class FingerprintLockScreen extends StatefulWidget {
  const FingerprintLockScreen({super.key});

  @override
  State<FingerprintLockScreen> createState() => _FingerprintLockScreenState();
}

class _FingerprintLockScreenState extends State<FingerprintLockScreen> {

  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Start biometric auth after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            children: [
              const Spacer(),
 
              // ── Fingerprint icon (animated pulse when scanning) ──
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _isAuthenticating
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: 64,
                  color: _isAuthenticating
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
 
              const SizedBox(height: 32),
 
              Text(
                'Welcome back!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
 
              const SizedBox(height: 12),
 
              Text(
                _isAuthenticating
                    ? 'Scanning fingerprint...'
                    : 'Touch the fingerprint sensor to unlock',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
 
              // ── Error message ──
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style:
                              const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
 
              const Spacer(),
 
              // ── Retry button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAuthenticating ? null : _authenticate,
                  icon: _isAuthenticating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.fingerprint),
                  label: Text(_isAuthenticating ? 'Scanning...' : 'Try Again'),
                ),
              ),
 
              const SizedBox(height: 12),
 
              // ── Fallback: use password ──
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isAuthenticating ? null : _usePasswordInstead,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Use Password Instead'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
