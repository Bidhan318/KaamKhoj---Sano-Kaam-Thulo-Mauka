// lib/screens/worker/worker_profile_screen.dart
//
// PURPOSE: Full profile page for a worker.
// Shows all details: photo, bio, skills, rate, rating breakdown,
// address, and hire/message CTAs. Opened from WorkerCard or BottomSheetWorker.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/distance_calculator.dart';
import '../../models/worker_model.dart';
import '../../providers/auth_provider.dart';
import '../chat/chat_screen.dart';

class WorkerProfileScreen extends StatelessWidget {
  final WorkerModel worker;

  const WorkerProfileScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Collapsible app bar with worker photo ──
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(worker.name),
              background: worker.profileImage != null
                  ? Image.network(worker.profileImage!, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      child: Center(
                        child: Text(
                          worker.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Status row ──
                Row(
                  children: [
                    // Availability
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: worker.isAvailable
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: worker.isAvailable
                                  ? AppColors.success
                                  : AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            worker.isAvailable
                                ? AppStrings.available
                                : AppStrings.unavailable,
                            style: TextStyle(
                              color: worker.isAvailable
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Rating
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: AppColors.accent, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          worker.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          ' / 5.0  (${worker.totalReviews})',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Stats row ──
                Row(
                  children: [
                    _StatBox(
                      icon: Icons.payments_outlined,
                      label: 'Rate',
                      value: 'NPR ${worker.ratePerDay.toInt()}/day',
                    ),
                    if (worker.distanceFromClient != null)
                      _StatBox(
                        icon: Icons.near_me,
                        label: 'Distance',
                        value: DistanceCalculator.formatDistance(
                            worker.distanceFromClient!),
                      ),
                    _StatBox(
                      icon: Icons.work_outline,
                      label: 'Jobs Done',
                      value: worker.totalReviews.toString(),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Location ──
                if (worker.address.isNotEmpty) ...[
                  const Text('Location',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.textSecondary, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          worker.address,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Skills ──
                const Text('Skills',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: worker.skills
                      .map((skill) => Chip(label: Text(skill)))
                      .toList(),
                ),

                const SizedBox(height: 32),

                // ── Action buttons ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(worker: worker),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text(AppStrings.message),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: worker.isAvailable
                            ? () {
                                // TODO: Implement hire flow
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Hire flow coming soon!')),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.handshake_outlined),
                        label: const Text(AppStrings.hireNow),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
} 