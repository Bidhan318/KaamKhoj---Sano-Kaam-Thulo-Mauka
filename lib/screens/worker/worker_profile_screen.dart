// lib/screens/worker/worker_profile_screen.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/distance_calculator.dart';
import '../../models/worker_model.dart';
import '../chat/chat_screen.dart';
import '../../core/utils/profile_image_helper.dart';

class WorkerProfileScreen extends StatelessWidget {
  final WorkerModel worker;

  const WorkerProfileScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildPhotoBanner(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Center(
                  child: Text(
                    worker.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: _buildRatingRow()),
                const SizedBox(height: 18),
                _buildStatsRow(),
                const SizedBox(height: 20),
                if (worker.address.isNotEmpty) ...[
                  _sectionTitle('Location'),
                  const SizedBox(height: 8),
                  _buildLocationCard(),
                  const SizedBox(height: 20),
                ],
                _sectionTitle('Skills'),
                const SizedBox(height: 10),
                _buildSkills(),
                const SizedBox(height: 20),
                _sectionTitle('Ratings Breakdown'),
                const SizedBox(height: 8),
                _buildRatingsBreakdown(),
                const SizedBox(height: 24),
                _buildActionButtons(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Photo banner header (replaces old gradient/wave header) ────────────
  Widget _buildPhotoBanner(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 260,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            image: worker.profileImage != null
                ? DecorationImage(
              image: profileImageProvider(worker.profileImage!)!,
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: worker.profileImage == null
              ? Center(
            child: Text(
              worker.name.isNotEmpty
                  ? worker.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          )
              : null,
        ),

        // subtle bottom shadow so the photo blends into the page
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.30),
                ],
              ),
            ),
          ),
        ),

        // availability pill, bottom-right of the photo
        Positioned(
          right: 20,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: worker.isAvailable
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  worker.isAvailable
                      ? AppStrings.available
                      : AppStrings.unavailable,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // back button
        Positioned(
          top: 0,
          left: 8,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: List.generate(5, (i) {
            return Icon(
              i < worker.rating.round() ? Icons.star : Icons.star_border,
              size: 18,
              color: AppColors.accent,
            );
          }),
        ),
        const SizedBox(width: 6),
        Text(
          worker.rating.toStringAsFixed(1),
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        Text(
          ' / 5.0 · ${worker.totalReviews} reviews',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatCard(
          icon: Icons.payments_outlined,
          value: 'NPR ${worker.ratePerDay.toInt()}/day',
          label: 'Rate',
          tint: AppColors.skillPalette[0], // purple
        ),
        if (worker.distanceFromClient != null)
          _StatCard(
            icon: Icons.location_on_outlined,
            value: DistanceCalculator.formatDistance(
                worker.distanceFromClient!),
            label: 'Distance',
            tint: AppColors.skillPalette[3], // blue
          ),
        _StatCard(
          icon: Icons.task_alt_outlined,
          value: worker.totalReviews.toString(),
          label: 'Jobs Done',
          tint: AppColors.skillPalette[2], // amber/orange
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              worker.address,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkills() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(worker.skills.length, (i) {
        final color = AppColors.skillPalette[i % AppColors.skillPalette.length];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
    );
  }

  Widget _buildRatingsBreakdown() {
    final total = worker.totalReviews == 0 ? 1 : worker.totalReviews;
    final dist = _estimateDistribution(worker.rating, worker.totalReviews);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                worker.rating.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < worker.rating.round()
                        ? Icons.star
                        : Icons.star_border,
                    size: 14,
                    color: AppColors.accent,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${worker.totalReviews}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = dist[star] ?? 0;
                final frac = count / total;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(
                        '$star ★',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: frac,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFF0F0F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 20,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Map<int, int> _estimateDistribution(double rating, int total) {
    if (total == 0) return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    final fiveShare = ((rating - 1) / 4).clamp(0.0, 1.0);
    final five = (total * fiveShare * 0.65).round();
    final four = (total * 0.2).round();
    final three = (total * 0.08).round();
    final two = (total * 0.04).round();
    final one = total - five - four - three - two;
    return {
      5: five,
      4: four,
      3: three,
      2: two < 0 ? 0 : two,
      1: one < 0 ? 0 : one
    };
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Message — white pill, outlined
        Expanded(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(worker: worker),
                ),
              ),
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
        // Hire Now — indigo-to-violet gradient pill
        Expanded(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: worker.isAvailable
                  ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Hire flow coming soon!')),
                );
              }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: worker.isAvailable ? AppColors.primaryGradient : null,
                  color: worker.isAvailable ? null : AppColors.divider,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.handshake_outlined,
                      size: 18,
                      color: worker.isAvailable
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.hireNow,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: worker.isAvailable
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color tint;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tint.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: tint),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}