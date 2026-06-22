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
                  // Avatar with a colored ring (green = available, red = unavailable)
                  // matching the status ring used on the Worker Card / Profile screen.
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: worker.isAvailable
                            ? [Colors.green.shade400, Colors.green.shade700]
                            : [Colors.red.shade400, Colors.red.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: worker.profileImage != null
                            ? profileImageProvider(worker.profileImage!)!
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
                    ),
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

              // ── Info row: Distance | Rate — tinted boxes, matching the
              // Rate/Distance/Jobs cards on the full Worker Profile screen ──
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: worker.distanceFromClient != null
                        ? DistanceCalculator.formatDistance(
                        worker.distanceFromClient!)
                        : worker.address,
                    tint: AppColors.skillPalette[3], // blue
                  ),
                  const SizedBox(width: 10),
                  _InfoChip(
                    icon: Icons.payments_outlined,
                    label: 'NPR ${worker.ratePerDay.toInt()}/day',
                    tint: AppColors.skillPalette[0], // purple
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Skills — multi-colored pills, same palette as everywhere else ──
              if (worker.skills.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(worker.skills.length, (i) {
                      final color =
                      AppColors.skillPalette[i % AppColors.skillPalette.length];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          border: Border.all(color: color.withValues(alpha: 0.45)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          worker.skills[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Action buttons — same pill shapes as Worker Profile screen ──
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(worker: worker),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.chat_bubble_outline,
                                  size: 18, color: AppColors.textPrimary),
                              SizedBox(width: 8),
                              Text(
                                AppStrings.message,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkerProfileScreen(worker: worker),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.handshake_outlined,
                                  size: 18, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                AppStrings.hireNow,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
  final Color tint;

  const _InfoChip({required this.icon, required this.label, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tint.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: tint),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}