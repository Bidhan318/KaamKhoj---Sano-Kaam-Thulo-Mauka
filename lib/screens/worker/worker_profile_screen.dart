// lib/screens/worker/worker_profile_screen.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/distance_calculator.dart';
import '../../models/worker_model.dart';
import '../chat/chat_screen.dart';

class WorkerProfileScreen extends StatelessWidget {
  final WorkerModel worker;

  const WorkerProfileScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildRatingRow(),
                const SizedBox(height: 14),
                _buildStatsRow(),
                const SizedBox(height: 16),
                if (worker.address.isNotEmpty) ...[
                  _sectionTitle('Location'),
                  const SizedBox(height: 8),
                  _buildLocationCard(),
                  const SizedBox(height: 16),
                ],
                _sectionTitle('Skills'),
                const SizedBox(height: 8),
                _buildSkills(),
                const SizedBox(height: 16),
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

  Widget _buildHeader(BuildContext context) {
    return Stack(
      // CHANGED: removed SizedBox fixed height — was device-specific and caused overflow
      // clipBehavior none so the wave at bottom isn't clipped
      clipBehavior: Clip.none,
      children: [
        // CHANGED: Column directly in Stack instead of Positioned.fill + fixed bottom:28
        // This lets the Stack naturally size to its content height
        Column(
          children: [
            Container(
              color: AppColors.primary,
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 28), // space for wave overlap
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: worker.profileImage != null
                            ? DecorationImage(
                          image: NetworkImage(worker.profileImage!),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: worker.profileImage == null
                          ? Center(
                        child: Text(
                          worker.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      worker.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      worker.phone,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: worker.isAvailable
                                  ? const Color(0xFF69F0AE)
                                  : AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            worker.isAvailable
                                ? AppStrings.available
                                : AppStrings.unavailable,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),

        // CHANGED: wave sits at bottom of the Stack using Positioned
        // bottom: 0 here is relative to the Column's natural height, not a fixed value
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ClipPath(
            clipper: _WaveClipper(),
            child: Container(height: 28, color: AppColors.background),
          ),
        ),

        // Back button
        Positioned(
          top: 0,
          left: 8,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
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
          emoji: '💰',
          value: 'NPR ${worker.ratePerDay.toInt()}/day',
          label: 'Rate',
        ),
        if (worker.distanceFromClient != null)
          _StatCard(
            emoji: '📍',
            value: DistanceCalculator.formatDistance(
                worker.distanceFromClient!),
            label: 'Distance',
          ),
        _StatCard(
          emoji: '🧱',
          value: worker.totalReviews.toString(),
          label: 'Jobs Done',
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.error, size: 16),
          const SizedBox(width: 6),
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
      runSpacing: 6,
      children: worker.skills
          .map(
            (skill) => Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            border: Border.all(color: const Color(0xFFFFB74D)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            skill,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFE65100),
            ),
          ),
        ),
      )
          .toList(),
    );
  }

  Widget _buildRatingsBreakdown() {
    final total = worker.totalReviews == 0 ? 1 : worker.totalReviews;
    final dist = _estimateDistribution(worker.rating, worker.totalReviews);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Hire flow coming soon!')),
              );
            }
                : null,
            icon: const Icon(Icons.handshake_outlined),
            label: const Text(AppStrings.hireNow),
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

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(
        size.width * 0.25, 0, size.width * 0.5, size.height * 0.6);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 1.2, size.width, size.height * 0.4);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper old) => false;
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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