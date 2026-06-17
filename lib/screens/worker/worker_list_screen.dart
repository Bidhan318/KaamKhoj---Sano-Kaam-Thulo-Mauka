// lib/screens/worker/worker_list_screen.dart
//
// PURPOSE: A scrollable list of nearby workers with search and skill filtering.
// Alternative to the map view – useful when the user wants to compare workers
// side by side rather than see them spatially.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/location_provider.dart';
import '../../providers/worker_provider.dart';
import '../../widgets/worker_card.dart';

// Common skill categories for Nepal context
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

class WorkerListScreen extends StatefulWidget {
  const WorkerListScreen({super.key});

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  String _selectedSkill = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchWorkers());
  }

  Future<void> _fetchWorkers() async {
    final location = context.read<LocationProvider>();
    final workers = context.read<WorkerProvider>();
    if (location.hasLocation) {
      await workers.fetchNearbyWorkers(
        clientLat: location.latitude,
        clientLon: location.longitude,
      );
    }
  }

  void _onSkillSelected(String skill) {
    setState(() => _selectedSkill = skill);
    final workerProvider = context.read<WorkerProvider>();
    workerProvider.setSkillFilter(skill == 'All' ? '' : skill);
    _fetchWorkers();
  }

  @override
  Widget build(BuildContext context) {
    final workerProvider = context.watch<WorkerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.findWorkers),
      ),
      body: Column(
        children: [
          // ── Search radius slider ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.radar, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text('${workerProvider.searchRadius.toInt()} km radius'),
                Expanded(
                  child: Slider(
                    value: workerProvider.searchRadius,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: '${workerProvider.searchRadius.toInt()} km',
                    onChanged: (val) {
                      workerProvider.setSearchRadius(val);
                    },
                    onChangeEnd: (_) => _fetchWorkers(),
                  ),
                ),
              ],
            ),
          ),

          // ── Skill filter chips ────────────────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _kSkillCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final skill = _kSkillCategories[i];
                final isSelected = skill == _selectedSkill;
                return FilterChip(
                  label: Text(skill),
                  selected: isSelected,
                  onSelected: (_) => _onSkillSelected(skill),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  checkmarkColor: Colors.white,
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ── Worker list ───────────────────────────────────────────────────
          Expanded(
            child: workerProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : workerProvider.nearbyWorkers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off,
                                  size: 48, color: AppColors.textSecondary),
                              const SizedBox(height: 16),
                              const Text(
                                AppStrings.noWorkersFound,
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: () {
                                  workerProvider.setSearchRadius(10);
                                  _fetchWorkers();
                                },
                                child: const Text('Expand to 10 km'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchWorkers,
                        child: ListView.builder(
                          itemCount: workerProvider.nearbyWorkers.length,
                          itemBuilder: (context, i) => WorkerCard(
                            worker: workerProvider.nearbyWorkers[i],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}