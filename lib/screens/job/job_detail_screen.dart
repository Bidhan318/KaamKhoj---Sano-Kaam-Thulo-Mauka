// lib/screens/job/job_detail_screen.dart
//
// PURPOSE: Full detail view of a posted job.
// Shown to workers browsing open jobs. Displays client info, skill needed,
// budget, location, and description. Worker can accept the job from here.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';

class JobDetailScreen extends StatelessWidget {
  final JobModel job;

  const JobDetailScreen({super.key, required this.job});

  Future<void> _acceptJob(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(job.jobId)
          .update({
        'status': 'assigned',
        'assignedWorkerUid': auth.user!.uid,
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job accepted! Contact the client via chat.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWorker = auth.isWorker;
    final isOpen = job.status == 'open';

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status badge ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(job.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                job.status.toUpperCase(),
                style: TextStyle(
                  color: _statusColor(job.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Title ──
            Text(job.title,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),

            // ── Posted by ──
            Text('Posted by ${job.clientName}',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),

            _DetailRow(icon: Icons.construction, label: 'Skill Required', value: job.requiredSkill),
            _DetailRow(icon: Icons.payments_outlined, label: 'Budget', value: 'NPR ${job.budget.toInt()}'),
            _DetailRow(icon: Icons.location_on_outlined, label: 'Location', value: job.address.isNotEmpty ? job.address : '${job.latitude.toStringAsFixed(4)}, ${job.longitude.toStringAsFixed(4)}'),
            _DetailRow(icon: Icons.schedule, label: 'Posted', value: _formatDate(job.postedAt)),

            const Divider(height: 32),

            // ── Description ──
            const Text('Description',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Text(job.description,
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.5)),

            const SizedBox(height: 32),

            // ── Accept button (workers only, open jobs only) ──
            if (isWorker && isOpen)
              ElevatedButton.icon(
                onPressed: () => _acceptJob(context),
                icon: const Icon(Icons.handshake_outlined),
                label: const Text('Accept This Job'),
              ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.success;
      case 'assigned':
        return AppColors.warning;
      case 'completed':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}