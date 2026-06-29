//PURPOSE: Shown ONCE after a successful first-time email/password login.
// Asks the user if they want to enable fingerprint login.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8EAF6),
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
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              children: [
                const Spacer(),
                // Icon
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF14A085).withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.fingerprint,
                      size: 64,
                      color: Color(0xFF2E3F80),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Title
                Text(
                  'Enable Fingerprint Login?',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1A1A2C),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Next time you open KaamKhoj, just tap your fingerprint — no need to type your password.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: Color(0xFF14A085)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your login details are stored securely on this device only.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF1A1A2C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Enable button
                StatefulBuilder(
                  builder: (context, setStateBtn) {
                    bool isPressed = false;
                    return GestureDetector(
                      onTapDown: (_) => setStateBtn(() => isPressed = true),
                      onTapUp: (_) => setStateBtn(() => isPressed = false),
                      onTapCancel: () => setStateBtn(() => isPressed = false),
                      onTap: _isProcessing ? null : _enableFingerprint,
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
                              colors: [Color(0xFF2E3F80), Color(0xFF14A085)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF14A085).withOpacity(0.35),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.fingerprint, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Enable Fingerprint',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Skip button
                TextButton(
                  onPressed: _isProcessing ? null : _skip,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: Text(
                    'Skip for now',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
  