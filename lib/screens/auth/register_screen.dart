// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _rateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'client';
  String _selectedSkill = 'Electrician';

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
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    await auth.createProfile(
      name: _nameController.text.trim(),
      role: _selectedRole,
      skill: _selectedRole == 'worker' ? _selectedSkill : null,
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tell us about yourself',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),

              // ── Name ──
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: AppStrings.name,
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 24),

              // ── Role Selection ──
              Text(AppStrings.selectRole,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      label: AppStrings.client,
                      icon: Icons.search,
                      description: 'I need to hire workers',
                      isSelected: _selectedRole == 'client',
                      onTap: () => setState(() => _selectedRole = 'client'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleCard(
                      label: AppStrings.worker,
                      icon: Icons.construction,
                      description: 'I offer services',
                      isSelected: _selectedRole == 'worker',
                      onTap: () => setState(() => _selectedRole = 'worker'),
                    ),
                  ),
                ],
              ),

              // ── Worker Extra Fields (only shown when worker selected) ──
              if (_selectedRole == 'worker') ...[
                const SizedBox(height: 24),
                Text('Worker Details',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedSkill,
                  decoration: const InputDecoration(
                    labelText: 'Your Skill',
                    prefixIcon: Icon(Icons.build_outlined),
                  ),
                  items: _skills
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSkill = v!),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _rateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Rate per Day (NPR)',
                    prefixIcon: Icon(Icons.currency_rupee),
                    hintText: 'e.g. 1500',
                  ),
                  validator: (v) {
                    if (_selectedRole != 'worker') return null;
                    if (v == null || v.trim().isEmpty) return 'Rate is required';
                    if (double.tryParse(v) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _onRegister,
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ),

              if (auth.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(auth.errorMessage!,
                    style: const TextStyle(color: AppColors.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 36,
                color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                )),
            const SizedBox(height: 4),
            Text(description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}