// lib/widgets/distance_badge.dart
//
// PURPOSE: A small pill-shaped badge showing distance (e.g. "1.2 km").
// Used on worker cards and map pop-ups. Reusable wherever distance is shown.

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/distance_calculator.dart';

class DistanceBadge extends StatelessWidget {
  final double distanceKm;

  const DistanceBadge({super.key, required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            DistanceCalculator.formatDistance(distanceKm),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}