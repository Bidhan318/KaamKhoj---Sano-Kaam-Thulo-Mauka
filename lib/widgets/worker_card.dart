// lib/widgets/worker_card.dart
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/distance_calculator.dart';
import '../models/worker_model.dart';
import '../screens/worker/worker_profile_screen.dart';

class WorkerCard extends StatelessWidget {
  final WorkerModel worker;

  const WorkerCard({super.key, required this.worker});

  Widget _buildSkillPill(String skill, int index) {
    // Generate different pastel borders based on index
    final colors = [
      const Color(0xFF5E35B1),
      const Color(0xFF00897B),
      const Color(0xFFF9A825),
      const Color(0xFFE53935),
    ];
    final color = colors[index % colors.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        skill,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WorkerProfileScreen(worker: worker)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Avatar with Ring ──
                Container(
                  padding: const EdgeInsets.all(3), // Border width
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
                    padding: const EdgeInsets.all(2), // Inner white spacing
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: worker.profileImage != null
                          ? NetworkImage(worker.profileImage!)
                          : null,
                      child: worker.profileImage == null
                          ? Text(
                              worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5E35B1),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),

                // ── Details ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Name
                      Text(
                        worker.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1F36),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Skills
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Skills: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: List.generate(
                                worker.skills.take(3).length,
                                (i) => _buildSkillPill(worker.skills[i], i),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 10),

                      // Rating & Rate row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < worker.rating.round() ? Icons.star : Icons.star_border,
                                size: 14,
                                color: const Color(0xFFF9A825), // Amber
                              );
                            }),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              const Text(
                                'Rate',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),

                      // Distance & Price row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                worker.distanceFromClient != null
                                    ? DistanceCalculator.formatDistance(worker.distanceFromClient!)
                                    : 'Unknown',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1F36),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'NPR ${worker.ratePerDay.toInt()}/day',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1F36),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}