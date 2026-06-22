// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _rateController = TextEditingController();
  final _customSkillController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedRole = 'client';
  String _selectedSkill = 'Electrician';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<String> _skills = [
    'Electrician',
    'Plumber',
    'Carpenter',
    'Mason',
    'Tutor',
    'Painter',
    'Mechanic',
    'Cleaner',
    'Gardner',
    'Driver',
    'Cook',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _rateController.dispose();
    _customSkillController.dispose();
    super.dispose();
  }

  String get _effectiveSkill {
    if (_selectedSkill == 'Other') {
      return _customSkillController.text.trim().isNotEmpty
          ? _customSkillController.text.trim()
          : 'Other';
    }
    return _selectedSkill;
  }

  void _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    await auth.createProfile(
      name: _nameController.text.trim(),
      role: _selectedRole,
      skill: _selectedRole == 'worker' ? _effectiveSkill : null,
      ratePerDay: _selectedRole == 'worker'
          ? (double.tryParse(_rateController.text.trim()) ?? 0.0)
          : null,
    );

    if (!mounted) return;
    if (context.read<AuthProvider>().isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _onBack() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Registration?'),
        content: const Text(
          'Your account will be removed and you\'ll need to register again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Registration'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().cancelRegistration();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Gradient header background ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar with back button ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: _onBack,
                        tooltip: 'Cancel Registration',
                      ),
                      const Spacer(),
                      Text(
                        'Create Profile',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // balance the back button
                    ],
                  ),
                ),

                // ── Form body ──
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Section: Name ──
                              _sectionTitle('Tell us about yourself'),
                              const SizedBox(height: 16),
                              _themedTextField(
                                controller: _nameController,
                                label: AppStrings.name,
                                icon: Icons.person_outline,
                                textCapitalization: TextCapitalization.words,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Name is required'
                                    : null,
                              ),
                              const SizedBox(height: 28),

                              // ── Section: Role Selection ──
                              _sectionTitle(AppStrings.selectRole),
                              const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _RoleCard(
                                        label: AppStrings.client,
                                        icon: Icons.search,
                                        description: 'I need to hire workers',
                                        isSelected: _selectedRole == 'client',
                                        onTap: () =>
                                          setState(() => _selectedRole = 'client'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                        child: _RoleCard(
                                          label: AppStrings.worker,
                                          icon: Icons.construction,
                                          description: 'I offer services',
                                          isSelected: _selectedRole == 'worker',
                                          onTap: () =>
                                            setState(() => _selectedRole = 'worker'),
                                          ),
                                        ),
                                      ],
                                  ),
                              
                              // ── Worker Extra Fields ──
                              if (_selectedRole == 'worker') ...[
                                const SizedBox(height: 28),
                                _sectionTitle('Worker Details'),
                                const SizedBox(height: 12),

                                // Skill dropdown
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedSkill,
                                    decoration: InputDecoration(
                                      labelText: 'Your Skill',
                                      labelStyle: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      prefixIcon: Icon(Icons.build_outlined,
                                          color: AppColors.secondary, size: 22),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      contentPadding:
                                          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                    ),
                                    icon: Icon(Icons.keyboard_arrow_down,
                                        color: AppColors.secondary),
                                    items: _skills
                                        .map((s) =>
                                            DropdownMenuItem(value: s, child: Text(s)))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedSkill = v!),
                                  ),
                                ),

                                // Custom skill input when "Other" is selected
                                if (_selectedSkill == 'Other') ...[
                                  const SizedBox(height: 12),
                                  _themedTextField(
                                    controller: _customSkillController,
                                    label: 'Your Custom Skill',
                                    icon: Icons.star_outline,
                                    hint: 'e.g. Photographer, Tailor, Welder',
                                    textCapitalization: TextCapitalization.words,
                                    validator: (v) {
                                      if (_selectedSkill != 'Other') return null;
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Please enter your skill';
                                      }
                                      return null;
                                    },
                                  ),
                                ],

                                const SizedBox(height: 12),
                                _themedTextField(
                                  controller: _rateController,
                                  label: 'Rate per Day (NPR)',
                                  icon: Icons.currency_rupee,
                                  hint: 'e.g. 1500',
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (_selectedRole != 'worker') return null;
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Rate is required';
                                    }
                                    if (double.tryParse(v) == null) {
                                      return 'Enter a valid number';
                                    }
                                    return null;
                                  },
                                ),
                              ],

                              const SizedBox(height: 36),

                              // ── Gradient Continue Button ──
                              _buildGradientButton(
                                text: 'Continue',
                                isLoading: auth.isLoading,
                                onPressed: _onRegister,
                              ),

                              if (auth.errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.error.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: AppColors.error, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          auth.errorMessage!,
                                          style: const TextStyle(
                                            color: AppColors.error,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _themedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        textCapitalization: textCapitalization,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.secondary, size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
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
                  colors: [Color(0xFF1E293B), Color(0xFF0F766E)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.35),
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
      },
    );
  }
}

// ── Role Card Widget ──────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondary.withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: isSelected ? AppColors.secondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected ? AppColors.secondary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? AppColors.secondary.withValues(alpha: 0.7)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}