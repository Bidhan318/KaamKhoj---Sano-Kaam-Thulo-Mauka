// lib/screens/job/job_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../chat/chat_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final JobModel job;

  const JobDetailScreen({super.key, required this.job});

  Future<void> _acceptJob(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    try {
      // Check if worker already has an active assigned job
      final activeJobsQuery = await FirebaseFirestore.instance
          .collection('jobs')
          .where('assignedWorkerUid', isEqualTo: auth.user!.uid)
          .where('status', isEqualTo: 'assigned')
          .get();
          
      if (activeJobsQuery.docs.isNotEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only accept one job at a time. Please finish your ongoing work first.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(job.jobId)
          .update({
        'status': 'assigned',
        'assignedWorkerUid': auth.user!.uid,
        'startedAt': DateTime.now().toIso8601String(),
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job accepted! Routing you to the location...'),
          backgroundColor: AppColors.success,
        ),
      );
      // Navigate back to the home map so they can see the route
      Navigator.popUntil(context, (route) => route.isFirst);
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
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: Center(
                  child: Icon(
                    Icons.work_outline,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
              title: Text(
                job.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header Row (Status & Client) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              job.clientName.isNotEmpty ? job.clientName[0].toUpperCase() : 'C',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FutureBuilder<String?>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(job.clientUid)
                                .get()
                                .then((doc) => doc.data()?['email'] as String?),
                            builder: (context, snap) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Posted by', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  Text(job.clientName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  if (snap.hasData && snap.data != null)
                                    Text(snap.data!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor(job.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _statusColor(job.status).withValues(alpha: 0.3)),
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
                    ],
                  ),
                  
                  const SizedBox(height: 32),

                  // ── Info Grid ──
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.15,
                    children: [
                      _buildInfoCard(Icons.construction, 'Skill', job.requiredSkill),
                      _buildInfoCard(Icons.payments_outlined, 'Budget', 'NPR ${job.budget.toInt()}'),
                      _buildInfoCard(Icons.location_on_outlined, 'Location', job.address.isNotEmpty ? job.address : 'Not specified'),
                      _buildInfoCard(Icons.schedule, 'Posted', _formatDate(job.postedAt)),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Description ──
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Text(
                      job.description,
                      style: const TextStyle(color: AppColors.textSecondary, height: 1.6, fontSize: 15),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Action Buttons ──
                  if (isWorker) ...[
                    Row(
                      children: [
                        // Message Client
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  otherUid: job.clientUid,
                                  otherName: job.clientName,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Message'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Accept Job
                        if (isOpen)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _acceptJob(context),
                              icon: const Icon(Icons.handshake_outlined),
                              label: const Text('Accept Job'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open': return AppColors.success;
      case 'assigned': return AppColors.warning;
      case 'completed': return AppColors.primary;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}