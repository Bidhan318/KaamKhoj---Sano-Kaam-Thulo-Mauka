import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/worker_provider.dart';
import '../../core/utils/distance_calculator.dart';
import '../../widgets/distance_badge.dart';
import 'job_detail_screen.dart';

const List<String> _kSkillCategories = [
  'All',
  'Electrician',
  'Plumber',
  'Carpenter',
  'Painter',
  'Mason',
  'Tutor',
  'Driver',
  'Cook',
  'Cleaner',
];

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  String _selectedSkill = 'All';
  String _searchQuery = '';
  double _searchRadius = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Gradient Header Background ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 240,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Bar ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      onPressed: () {
                        setState(() {});
                      },
                    ),
                  ],
                ),
                
                // ── Title ──
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Find Jobs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // ── Search Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(27),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search jobs by title or skill...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // ── Skill Filters ──
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Skill Filters',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _kSkillCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final skill = _kSkillCategories[i];
                      final isSelected = skill == _selectedSkill;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSkill = skill;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? AppColors.primaryGradient
                                : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? null
                                : Border.all(color: Colors.grey.shade300),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Text(
                            skill,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // ── Search Radius ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      const Text(
                        'Radius',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_searchRadius.toInt()} km',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: Colors.grey.shade300,
                      thumbColor: Colors.white,
                      overlayColor: AppColors.primary.withValues(alpha: 0.2),
                      trackHeight: 4.0,
                    ),
                    child: Slider(
                      value: _searchRadius,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      onChanged: (val) {
                        setState(() {
                          _searchRadius = val;
                        });
                      },
                    ),
                  ),
                ),
                
                // ── Job List ──
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final currentUid = context.read<AuthProvider>().user?.uid;
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('jobs')
                            .where('status', isEqualTo: 'open')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.work_off, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  Text('No open jobs yet',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                                ],
                              ),
                            );
                          }

                          var jobs = snapshot.data!.docs
                              .map((doc) => JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                              .where((job) {
                                if (job.isDirectHire) {
                                  // Show direct hire jobs ONLY to the worker being hired
                                  return job.assignedWorkerUid == currentUid;
                                } else {
                                  // Normal open jobs show to everyone
                                  return job.assignedWorkerUid == null;
                                }
                              })
                              .toList();

                      // Sort locally
                      jobs.sort((a, b) => b.postedAt.compareTo(a.postedAt));

                      // Apply skill filter
                      if (_selectedSkill != 'All') {
                        jobs = jobs.where((j) => j.requiredSkill.toLowerCase() == _selectedSkill.toLowerCase()).toList();
                      }

                      // Apply search query
                      if (_searchQuery.isNotEmpty) {
                        jobs = jobs.where((j) => 
                          j.title.toLowerCase().contains(_searchQuery) ||
                          j.requiredSkill.toLowerCase().contains(_searchQuery)
                        ).toList();
                      }

                      // Apply distance filter
                      final locationProvider = context.read<LocationProvider>();
                      if (locationProvider.hasLocation) {
                        jobs = jobs.where((j) {
                          final dist = DistanceCalculator.calculateDistance(
                            lat1: locationProvider.latitude,
                            lon1: locationProvider.longitude,
                            lat2: j.latitude,
                            lon2: j.longitude,
                          );
                          return dist <= _searchRadius;
                        }).toList();
                      }

                      if (jobs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text('No jobs match your search',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async { setState(() {}); },
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 24),
                          itemCount: jobs.length,
                          itemBuilder: (context, i) => JobCard(job: jobs[i]),
                        ),
                      );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final JobModel job;
  
  const JobCard({super.key, required this.job});

  Widget _buildSkillPill(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Text(
        skill,
        style: const TextStyle(
          color: AppColors.primary,
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
        color: AppColors.surface,
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
            MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Client Avatar with Ring ──
                Container(
                  padding: const EdgeInsets.all(3), // Border width
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2), // Inner white spacing
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        job.clientName.isNotEmpty ? job.clientName[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
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
                      // Title
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'OPEN',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Required Skill
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Need: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          _buildSkillPill(job.requiredSkill),
                        ],
                      ),
                      
                      const SizedBox(height: 10),

                      // Client name row
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            job.clientName,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),

                      // Location & Budget row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Consumer<LocationProvider>(
                            builder: (context, locationProvider, child) {
                              if (locationProvider.hasLocation) {
                                final distance = DistanceCalculator.calculateDistance(
                                  lat1: locationProvider.latitude,
                                  lon1: locationProvider.longitude,
                                  lat2: job.latitude,
                                  lon2: job.longitude,
                                );
                                return DistanceBadge(distanceKm: distance);
                              }
                              return Row(
                                children: const [
                                  Icon(Icons.location_on, size: 12, color: AppColors.textSecondary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Unknown',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          Text(
                            'NPR ${job.budget.toInt()}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
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
