//PURPOSE: Shown ONCE after a successful first-time email/password login.
// Asks the user if they want to enable fingerprint login.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';


class FingerprintSetupScreen extends StatefulWidget {
  /// The credentials that just succeeded — needed to store them if user agrees.
  final String email;
  final String password;
 
  const FingerprintSetupScreen({
    super.key,
    required this.email,
    required this.password,
  });

   @override
  State<FingerprintSetupScreen> createState() => _FingerprintSetupScreenState();
}

class _FingerprintSetupScreenState extends State<FingerprintSetupScreen> {
 
  bool _isProcessing = false;
 
  Future<void> _enableFingerprint() async {
    setState(() => _isProcessing = true);
 
    final auth = context.read<AuthProvider>();
    final success = await auth.enableBiometric(
      email: widget.email,
      password: widget.password,
    );
    if (!mounted) return;
    setState(() => _isProcessing = false);

   if(success){
    _goHome();
   }else{
       // Fingerprint scan failed or was cancelled — let user try again or skip
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fingerprint not recognised. You can set it up later.'),
        ),
      );
    }
  }  

  void _skip() {
    // Mark that we've asked — don't ask again until next fresh login
    context.read<AuthProvider>().skipBiometricSetup();
    _goHome();
  }
 
  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
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
 
              // ── Icon ──
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
 
              const SizedBox(height: 32),
 
              // ── Title ──
              Text(
                'Enable Fingerprint Login?',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
 
              const SizedBox(height: 16),
 
              Text(
                'Next time you open KaamKhoj, just tap your fingerprint — '
                'no need to type your password.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
 
              const SizedBox(height: 12),
 
              // Small note about what gets stored
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your login details are stored securely on this device only.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
 
              const Spacer(),
 
              // ── Enable button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _enableFingerprint,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.fingerprint),
                  label:
                      Text(_isProcessing ? 'Scanning...' : 'Enable Fingerprint'),
                ),
              ),
 
              const SizedBox(height: 12),
 
              // ── Skip button ──
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isProcessing ? null : _skip,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
  