// lib/screens/worker/hire_worker_screen.dart
//
// PURPOSE: Screen for clients to hire a worker directly.
// Displays the worker's name and skill as fixed parameters, shows current location,
// and requests job description and budget.
// Creates a job document with status 'requested' and assignedWorkerUid.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/job_model.dart';
import '../../models/worker_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../core/utils/profile_image_helper.dart';

class HireWorkerScreen extends StatefulWidget {
  final WorkerModel worker;

  const HireWorkerScreen({super.key, required this.worker});

  @override
  State<HireWorkerScreen> createState() => _HireWorkerScreenState();
}

class _HireWorkerScreenState extends State<HireWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final location = context.read<LocationProvider>();

    final primarySkill = widget.worker.skills.isNotEmpty ? widget.worker.skills.first : 'Worker';

    final job = JobModel(
      jobId: '', // Firestore will auto-generate
      clientUid: auth.user!.uid,
      clientName: auth.user!.name,
      title: 'Direct Hire: $primarySkill',
      description: _descriptionController.text.trim(),
      requiredSkill: primarySkill,
      budget: double.tryParse(_budgetController.text.trim()) ?? 0,
      latitude: location.latitude,
      longitude: location.longitude,
      address: location.currentAddress,
      status: 'open', // set to open so worker can accept under existing security rules
      assignedWorkerUid: widget.worker.uid, // directly assigned to this worker
      postedAt: DateTime.now(),
      isDirectHire: true,
    );

    try {
      await FirebaseFirestore.instance.collection('jobs').add(job.toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hire request sent to ${widget.worker.name}!'),
          backgroundColor: AppColors.success,
        ),
      );
      // Go back to worker profile
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
    final primarySkill = widget.worker.skills.isNotEmpty ? widget.worker.skills.first : 'Worker';
    final imageProvider = widget.worker.profileImage != null
        ? profileImageProvider(widget.worker.profileImage!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hire Worker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Location indicator (Top) ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location.hasLocation
                            ? location.currentAddress.isNotEmpty
                                ? location.currentAddress
                                : 'Location detected'
                            : 'Fetching location...',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Fixed Parameters: Target Worker Card ──
              const Text(
                'Hiring details',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? Text(
                              widget.worker.name.isNotEmpty ? widget.worker.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.worker.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Service: $primarySkill',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Job Description Form Field ──
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Job Description',
                  hintText: 'Describe the task you want this worker to perform...',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (v) => v == null || v.trim().length < 10
                    ? 'Please provide more detail (min 10 chars)'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Budget (NPR) Form Field ──
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Budget (NPR)',
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

              // ── Confirm & Cancel Buttons ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
