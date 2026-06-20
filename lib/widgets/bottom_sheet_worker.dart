// lib/widgets/bottom_sheet_worker.dart

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../models/worker_model.dart';
import '../core/utils/distance_calculator.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/worker/worker_profile_screen.dart';
import '../core/utils/profile_image_helper.dart';

class BottomSheetWorker extends StatelessWidget {
  final WorkerModel worker;
  final ScrollController? scrollController;

  const BottomSheetWorker({
    super.key,
    required this.worker,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ──
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Drag up to see full profile',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),

              // ── Worker header ──
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: worker.profileImage != null
                        ? profileImageProvider(worker.profileImage!)!
                        : null,
                    child: worker.profileImage == null
                        ? Text(
                      worker.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: AppColors.accent, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              worker.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              ' (${worker.totalReviews} reviews)',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Availability badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: worker.isAvailable
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      worker.isAvailable
                          ? AppStrings.available
                          : AppStrings.unavailable,
                      style: TextStyle(
                        color: worker.isAvailable
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // ── Info row: Distance | Rate ──
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: worker.distanceFromClient != null
                        ? DistanceCalculator.formatDistance(
                        worker.distanceFromClient!)
                        : worker.address,
                  ),
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.payments_outlined,
                    label: 'NPR ${worker.ratePerDay.toInt()}/day',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Skills ──
              if (worker.skills.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: worker.skills
                        .map((skill) => Chip(label: Text(skill)))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Action buttons ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(worker: worker),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text(AppStrings.message),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkerProfileScreen(worker: worker),
                          ),
                        );
                      },
                      icon: const Icon(Icons.handshake_outlined),
                      label: const Text(AppStrings.hireNow),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}