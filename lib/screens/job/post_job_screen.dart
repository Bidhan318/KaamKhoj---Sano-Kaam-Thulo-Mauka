// lib/screens/job/post_job_screen.dart
//
// PURPOSE: Form for clients to post a job request.
// Captures: title, description, required skill, budget, and uses the
// client's current location as the job location.
// Writes the job to Firestore /jobs collection.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';

const List<String> _kSkills = [
  'Electrician',
  'Plumber',
  'Carpenter',
  'Painter',
  'Mason',
  'Tutor',
  'Driver',
  'Cook',
  'Cleaner',
  'Other',
];

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  String _selectedSkill = _kSkills[0];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final location = context.read<LocationProvider>();

    final job = JobModel(
      jobId: '',                          // Firestore will auto-generate
      clientUid: auth.user!.uid,
      clientName: auth.user!.name,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      requiredSkill: _selectedSkill,
      budget: double.tryParse(_budgetController.text.trim()) ?? 0,
      latitude: location.latitude,
      longitude: location.longitude,
      address: location.currentAddress,
      postedAt: DateTime.now(),
    );

    try {
      await FirebaseFirestore.instance.collection('jobs').add(job.toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.jobPosted),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.postJob)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Location indicator ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location.hasLocation
                            ? location.currentAddress.isNotEmpty
                                ? location.currentAddress
                                : 'Location detected'
                            : 'Fetching location...',
                        style:
                            const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Job Title ──
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: AppStrings.jobTitle,
                  hintText: 'e.g. Fix leaking pipe in bathroom',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // ── Required Skill ──
              DropdownButtonFormField<String>(
                value: _selectedSkill,
                decoration: const InputDecoration(
                  labelText: AppStrings.requiredSkill,
                  prefixIcon: Icon(Icons.construction),
                ),
                items: _kSkills
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedSkill = val ?? _kSkills[0]),
              ),
              const SizedBox(height: 16),

              // ── Description ──
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: AppStrings.jobDescription,
                  hintText:
                      'Describe the problem or task in detail...',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (v) => v == null || v.trim().length < 10
                    ? 'Please provide more detail (min 10 chars)'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Budget ──
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: AppStrings.budget,
                  prefixText: 'NPR ',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a budget';
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // ── Submit button ──
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitJob,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                    _isSubmitting ? 'Posting...' : AppStrings.submitJob),
              ),
            ],
          ),
        ),
      ),
    );
  }
}