// lib/widgets/worker_card.dart
//
// PURPOSE: A reusable card widget for the WorkerListScreen.
// Shows avatar, name, skills, rating, distance, and rate at a glance.
// Tapping navigates to the full WorkerProfileScreen.

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/distance_calculator.dart';
import '../models/worker_model.dart';
import '../screens/worker/worker_profile_screen.dart';

class WorkerCard extends StatelessWidget {
  final WorkerModel worker;

  const WorkerCard({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WorkerProfileScreen(worker: worker)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ── Avatar ──
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: worker.profileImage != null
                    ? NetworkImage(worker.profileImage!)
                    : null,
                child: worker.profileImage == null
                    ? Text(
                        worker.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // ── Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + availability dot
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            worker.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
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
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Skills
                    Text(
                      worker.skills.take(3).join(' · '),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Rating | Distance | Rate
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: AppColors.accent),
                        const SizedBox(width: 2),
                        Text(
                          worker.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        if (worker.distanceFromClient != null) ...[
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            DistanceCalculator.formatDistance(
                                worker.distanceFromClient!),
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 12),
                        ],
                        const Icon(Icons.payments_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text(
                          'NPR ${worker.ratePerDay.toInt()}/d',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}