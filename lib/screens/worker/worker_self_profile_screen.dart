// lib/screens/worker/worker_self_profile_screen.dart
//
// PURPOSE: Lets a logged-in worker view how their profile looks to clients
// AND edit/save their profile. Two tabs: Preview (client view) + Edit Profile.
// Only shown to users with role='worker'.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/profile_image_helper.dart';
import '../../models/worker_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import 'worker_profile_screen.dart';

// Common skill options for Nepal context
const List<String> _kSkillOptions = [
  'Electrician',
  'Plumber',
  'Carpenter',
  'Painter',
  'Mason',
  'Tutor',
  'Driver',
  'Cook',
  'Cleaner',
  'Welder',
  'Mechanic',
  'Gardener',
  'Security Guard',
  'Helper',
];

class WorkerSelfProfileScreen extends StatefulWidget {
  const WorkerSelfProfileScreen({super.key});

  @override
  State<WorkerSelfProfileScreen> createState() =>
      _WorkerSelfProfileScreenState();
}

class _WorkerSelfProfileScreenState extends State<WorkerSelfProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

// Load worker profile on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<WorkerProvider>().loadMyWorkerProfile(auth.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workerProvider = context.watch<WorkerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        title: const Text('My Profile'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.preview_outlined), text: 'Client View'),
            Tab(icon: Icon(Icons.edit_outlined), text: 'Edit Profile'),
          ],
        ),
      ),
      body: workerProvider.isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : workerProvider.myWorkerProfile == null
          ? _buildNoProfile()
          : TabBarView(
        controller: _tabController,
        children: [
// Tab 1: How the client sees this worker
          _PreviewTab(worker: workerProvider.myWorkerProfile!),
// Tab 2: Edit form
          _EditTab(
            worker: workerProvider.myWorkerProfile!,
            onSaved: () {
// Switch back to preview after saving
              _tabController.animateTo(0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoProfile() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_off_outlined,
                  size: 56, color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Profile not found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your worker profile could not be loaded.\nPlease try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                if (auth.user != null) {
                  context
                      .read<WorkerProvider>()
                      .loadMyWorkerProfile(auth.user!.uid);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Preview — shows the existing WorkerProfileScreen but with a banner
// and without the hire/chat buttons (replaced by "Edit Profile" button).
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewTab extends StatelessWidget {
  final WorkerModel worker;
  const _PreviewTab({required this.worker});

  @override
  Widget build(BuildContext context) {
    return WorkerProfileScreen(
      worker: worker,
      showBackButton: false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Edit Profile form
// ─────────────────────────────────────────────────────────────────────────────

class _EditTab extends StatefulWidget {
  final WorkerModel worker;
  final VoidCallback onSaved;

  const _EditTab({required this.worker, required this.onSaved});

  @override
  State<_EditTab> createState() => _EditTabState();
}

class _EditTabState extends State<_EditTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCon = TextEditingController();
  final _phoneCon = TextEditingController();
  final _rateCon = TextEditingController();
  List<String> _skills = [];
  bool _isAvailable = true;
  File? _pickedImage;
  String? _currentImageUrl;
  bool _imageRemoved = false;

  @override
  void initState() {
    super.initState();
    _nameCon.text = widget.worker.name;
    _phoneCon.text = widget.worker.phone;
    _rateCon.text = widget.worker.ratePerDay.toInt().toString();
    _skills = List<String>.from(widget.worker.skills);
    _isAvailable = widget.worker.isAvailable;
    _currentImageUrl = widget.worker.profileImage;
  }

  @override
  void didUpdateWidget(_EditTab old) {
    super.didUpdateWidget(old);
// If the worker model refreshed from outside, sync only if user hasn't
// started editing (detect via form dirty state would be complex,
// so we just sync on first load above — this is fine for our use case)
  }

  @override
  void dispose() {
    _nameCon.dispose();
    _phoneCon.dispose();
    _rateCon.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
        _imageRemoved = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _currentImageUrl = null;
      _imageRemoved = true;
    });
  }

  void _addSkill(String skill) {
    if (!_skills.contains(skill)) {
      setState(() => _skills.add(skill));
    }
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one skill.')),
      );
      return;
    }

    final workerProvider = context.read<WorkerProvider>();
    String? imageUrl = _imageRemoved ? null : _currentImageUrl;

    try {
// Convert the picked image to a base64 string and save it straight into the Firestore document
      if (_pickedImage != null && !_imageRemoved) {
        final bytes = await _pickedImage!.readAsBytes();
        if (bytes.length > 700 * 1024) {
          throw Exception(
              'Photo is too large (${(bytes.length / 1024).round()} KB). '
                  'Please choose a smaller/simpler photo.');
        }
        imageUrl = base64Encode(bytes);
      }
      final updated = WorkerModel(
        uid: widget.worker.uid,
        email: widget.worker.email,
        name: _nameCon.text.trim(),
        phone: _phoneCon.text.trim(),
        profileImage: imageUrl,
        skills: _skills,
        ratePerDay: double.tryParse(_rateCon.text.trim()) ??
            widget.worker.ratePerDay,
        rating: widget.worker.rating,
        totalReviews: widget.worker.totalReviews,
        isAvailable: _isAvailable,
        latitude: widget.worker.latitude,
        longitude: widget.worker.longitude,
        address: widget.worker.address,
      );
      await workerProvider.saveWorkerProfile(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<WorkerProvider>().isLoading;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
// ── Profile Photo ─────────────────────────────────────────────
                  _buildPhotoCard(),
                  const SizedBox(height: 16),

// ── Availability toggle ───────────────────────────────────────
                  _buildAvailabilityToggle(),
                  const SizedBox(height: 16),

// ── Basic Info ────────────────────────────────────────────────
                  _buildInfoCard(isSaving),
                  const SizedBox(height: 16),

// ── Skills ────────────────────────────────────────────────────
                  _buildSkillsCard(),
                ],
              ),
            ),
          ),
        ),
        // ── Pinned Save Button ───────────────────────────────────────────────
        SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                top: BorderSide(color: AppColors.divider, width: 0.8),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: _buildSaveButton(isSaving),
          ),
        ),
      ],
    );
  }

  // ── Photo section wrapped in a themed card ──
  Widget _buildPhotoCard() {
    final hasImage = _pickedImage != null || _currentImageUrl != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section header with gradient accent
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.secondary.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              const Text(
                'Profile Photo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Avatar with gradient ring
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.secondary.withValues(alpha: 0.15),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: _pickedImage != null
                      ? DecorationImage(
                    image: FileImage(_pickedImage!),
                    fit: BoxFit.cover,
                  )
                      : (_currentImageUrl != null
                      ? DecorationImage(
                    image: profileImageProvider(_currentImageUrl)!,
                    fit: BoxFit.cover,
                  )
                      : null),
                ),
                child: (!hasImage)
                    ? Center(
                  child: Text(
                    widget.worker.name.isNotEmpty
                        ? widget.worker.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3F51B5), Color(0xFF009688)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library_outlined,
                    size: 16, color: AppColors.primary),
                label: const Text('Change Photo',
                    style: TextStyle(color: AppColors.primary)),
              ),
              if (hasImage) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: AppColors.error),
                  label: const Text('Remove',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isAvailable
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isAvailable ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated status indicator
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_isAvailable ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.12),
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isAvailable ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available for Work',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _isAvailable
                      ? 'Clients can see and contact you'
                      : 'You are hidden from client searches',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAvailable,
            onChanged: (val) => setState(() => _isAvailable = val),
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  // ── Info fields wrapped in a themed card ──
  Widget _buildInfoCard(bool isSaving) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.secondary.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_outline,
                    size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              const Text(
                'Basic Info',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _phoneCon,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'e.g. name@example.com',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Email is required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _rateCon,
            decoration: const InputDecoration(
              labelText: 'Daily Rate (NPR)',
              prefixIcon: Icon(Icons.payments_outlined),
              hintText: 'e.g. 1500',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Rate is required';
              final n = int.tryParse(v.trim());
              if (n == null || n <= 0) return 'Enter a valid rate';
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ── Skills section wrapped in a themed card ──
  Widget _buildSkillsCard() {
    final remaining =
    _kSkillOptions.where((s) => !_skills.contains(s)).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.secondary.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.construction_outlined,
                    size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              const Text(
                'Skills',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_skills.length} selected',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap to add or remove skills',
            style:
            TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // Current skills (removable)
          if (_skills.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: List.generate(_skills.length, (i) {
                final skill = _skills[i];
                final color =
                AppColors.skillPalette[i % AppColors.skillPalette.length];
                return Chip(
                  label: Text(skill),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => _removeSkill(skill),
                  backgroundColor: color.withValues(alpha: 0.10),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  side: BorderSide(color: color.withValues(alpha: 0.45)),
                  deleteIconColor: color,
                );
              }),
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.divider.withValues(alpha: 0.0),
                    AppColors.divider,
                    AppColors.divider.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Add skills from list
          if (remaining.isNotEmpty) ...[
            const Text(
              'Add skills:',
              style:
              TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: remaining
                  .map(
                    (skill) => ActionChip(
                  label: Text(skill),
                  avatar: const Icon(Icons.add,
                      size: 14, color: AppColors.primary),
                  onPressed: () => _addSkill(skill),
                  backgroundColor:
                  AppColors.primary.withValues(alpha: 0.06),
                  labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary),
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.35)),
                ),
              )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── Gradient save button matching auth screens ──
  Widget _buildSaveButton(bool isSaving) {
    return GestureDetector(
      onTap: isSaving ? null : _save,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isSaving
              ? null
              : const LinearGradient(
            colors: [Color(0xFF2E3F80), Color(0xFF14A085)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          color: isSaving ? AppColors.divider : null,
          borderRadius: BorderRadius.circular(28),
          boxShadow: isSaving
              ? null
              : [
            BoxShadow(
              color: const Color(0xFF14A085).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSaving)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.save_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              isSaving ? 'Saving…' : 'Save Profile',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}