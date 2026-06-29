// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/worker_model.dart';
import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/worker_provider.dart';
import '../../widgets/bottom_sheet_worker.dart';
import '../job/post_job_screen.dart';
import '../job/job_detail_screen.dart';
import '../job/job_list_screen.dart';
import '../worker/worker_list_screen.dart';
import '../auth/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/biometric_service.dart';
import '../chat/chat_list_screen.dart';
import '../worker/worker_profile_screen.dart';
import '../worker/worker_self_profile_screen.dart';
import '../../core/utils/profile_image_helper.dart';
import '../../core/services/routing_service.dart';
import '../chat/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  Map<String, List<LatLng>> _activeRoutes = {};
  Set<String> _fetchingRoutes = {};
  bool _hasOngoingJob = false;
  String? _selectedAssignedJobId;

  // Default: Kathmandu
  static const double _defaultLat = 27.7172;
  static const double _defaultLon = 85.3240;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final locationProvider = context.read<LocationProvider>();
    final authProvider = context.read<AuthProvider>();

    await locationProvider.fetchCurrentLocation();

    if (authProvider.isWorker) {
      locationProvider.startWorkerLocationStream(authProvider.user!.uid);
    }

    if (locationProvider.hasLocation) {
      _mapController.move(
        LatLng(locationProvider.latitude, locationProvider.longitude),
        14.0,
      );
    }
  }

  // ── Worker markers for CLIENT view ─────────────────────────────────────────
  List<Marker> _buildWorkerMarkers(List<WorkerModel> workers) {
    return workers.map((worker) {
      return Marker(
        point: LatLng(worker.latitude, worker.longitude),
        width: 100,
        height: 80,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => _onWorkerTapped(worker),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: worker.isAvailable ? Colors.green : Colors.red,
                    width: 3,
                  ),
                  color: Colors.white,
                  image: worker.profileImage != null
                      ? DecorationImage(
                          image: profileImageProvider(worker.profileImage!)!,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: worker.profileImage == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Text(
                  worker.isAvailable ? worker.name : 'Unavailable',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ── Job markers for WORKER view ────────────────────────────────────────────
  List<Marker> _buildJobMarkers(List<JobModel> jobs, {Set<String>? assignedJobIds}) {
    return jobs.map((job) {
      if (job.latitude == 0 && job.longitude == 0) return null;
      final isAssigned = assignedJobIds?.contains(job.jobId) ?? false;
      final markerColor = isAssigned ? Colors.green : Colors.orange;

      return Marker(
        point: LatLng(job.latitude, job.longitude),
        width: 100,
        height: 80,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => _onJobTapped(job),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: markerColor, width: 3),
                  color: Colors.white,
                ),
                child: Icon(Icons.work, color: markerColor),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Text(
                  'NPR ${job.budget.toInt()}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  void _onWorkerTapped(WorkerModel worker) {
    context.read<WorkerProvider>().selectWorker(worker);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) {
          return NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              if (notification.extent >= 0.88) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkerProfileScreen(worker: worker),
                  ),
                );
              }
              return false;
            },
            child: BottomSheetWorker(
              worker: worker,
              scrollController: scrollController,
            ),
          );
        },
      ),
    );
  }

  void _onJobTapped(JobModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();
    final auth = context.watch<AuthProvider>();
    final workerProvider = context.watch<WorkerProvider>();
    
    // During logout, auth.user becomes null before the screen navigates away.
    if (auth.user == null) {
      return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
    }

    final isWorker = auth.isWorker;

    final centerLat = location.hasLocation ? location.latitude : _defaultLat;
    final centerLon = location.hasLocation ? location.longitude : _defaultLon;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(auth),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          isWorker
              ? _buildWorkerMapView(centerLat, centerLon, location, auth)
              : _buildClientMapView(centerLat, centerLon, location, workerProvider, auth),

          // ── Custom Gradient Header ───────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 40,
                left: 16,
                right: 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'KaamKhoj',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            location.currentAddress.isNotEmpty ? location.currentAddress : 'Locating...',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(isWorker ? Icons.work_outline : Icons.people_outline, color: Colors.white),
                    tooltip: isWorker ? 'Browse Jobs' : 'Browse Workers',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => isWorker ? const JobListScreen() : const WorkerListScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Floating Search Bar ──────────────────────────────────────────
          if (!isWorker)
            Positioned(
              top: MediaQuery.of(context).padding.top + 100,
            left: 24,
            right: 24,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search workers by skill...',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                onChanged: (value) {
                  workerProvider.setSkillFilter(value);
                },
              ),
            ),
          ),



          // ── Loading overlay ───────────────────────────────────────────────
          if (location.isLoading)
            const Center(child: CircularProgressIndicator()),

          // ── Error banner ──────────────────────────────────────────────────
          if (location.errorMessage != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 160,
              left: 0,
              right: 0,
              child: Container(
                color: AppColors.error,
                padding: const EdgeInsets.all(8),
                child: Text(
                  location.errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // ── Bottom Action Buttons ─────────────────────────────────────────
          Positioned(
            bottom: _hasOngoingJob ? 220 : 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // My Location Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          await location.fetchCurrentLocation();
                          if (location.hasLocation) {
                            _mapController.move(
                              LatLng(location.latitude, location.longitude),
                              14.0,
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('My location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              SizedBox(width: 6),
                              Icon(Icons.my_location, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Post a Job Button
                if (!isWorker)
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F766E)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PostJobScreen()),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('Post a Job', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              SizedBox(width: 6),
                              Icon(Icons.add, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CLIENT view: shows worker pins ────────────────────────────────────────
  Widget _buildClientMapView(double centerLat, double centerLon,
      LocationProvider location, WorkerProvider workerProvider, AuthProvider auth) {
    return StreamBuilder<List<JobModel>>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('clientUid', isEqualTo: auth.user!.uid)
          .where('status', isEqualTo: 'assigned')
          .snapshots()
          .map((snap) => snap.docs.map((doc) => JobModel.fromMap(doc.data(), doc.id)).toList()),
      builder: (context, assignedSnapshot) {
        final assignedJobs = assignedSnapshot.data ?? [];
        final hasAssignedJob = assignedJobs.isNotEmpty;
        
        JobModel? assignedJob;
        if (hasAssignedJob) {
          if (_selectedAssignedJobId != null) {
            assignedJob = assignedJobs.where((j) => j.jobId == _selectedAssignedJobId).firstOrNull ?? assignedJobs.first;
          } else {
            assignedJob = assignedJobs.first;
          }
        }
        
        final assignedWorkerUid = assignedJob?.assignedWorkerUid;

        // Track ongoing job state for button positioning
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_hasOngoingJob != hasAssignedJob && mounted) {
            setState(() { _hasOngoingJob = hasAssignedJob; });
          }
        });

        // Clean up stale routes when job completes/cancels
        if (!hasAssignedJob && _activeRoutes.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() { _activeRoutes.clear(); _fetchingRoutes.clear(); });
          });
        }

        return StreamBuilder<List<WorkerModel>>(
          stream: location.hasLocation
              ? workerProvider.watchNearbyWorkers(
                  clientLat: centerLat, 
                  clientLon: centerLon,
                  radiusKm: hasAssignedJob ? 100 : null,
                )
              : const Stream.empty(),
          builder: (context, snapshot) {
            List<WorkerModel> allWorkers = snapshot.data ?? [];
            List<WorkerModel> displayWorkers = [];

            final query = workerProvider.skillFilter.toLowerCase();
            for (var w in allWorkers) {
               if (assignedWorkerUid != null && w.uid == assignedWorkerUid) {
                 displayWorkers.add(w);
               } else if (!hasAssignedJob && (query.isEmpty || w.skills.any((s) => s.toLowerCase().contains(query)))) {
                 displayWorkers.add(w);
               }
            }

            final workerMarkers = _buildWorkerMarkers(displayWorkers);
            final myMarker = _myLocationMarker(location);
            
            List<Marker> activeJobMarkers = [];
            if (hasAssignedJob && assignedJob != null) {
              activeJobMarkers = _buildJobMarkers([assignedJob], assignedJobIds: {assignedJob.jobId});
            }

            // Route from assigned worker to job location (single job only)
            if (hasAssignedJob && assignedJob != null && assignedWorkerUid != null) {
              final trackingWorker = displayWorkers.where((w) => w.uid == assignedWorkerUid).firstOrNull;
              if (trackingWorker != null) {
                if (!_activeRoutes.containsKey(assignedJob.jobId) && !_fetchingRoutes.contains(assignedJob.jobId)) {
                  _fetchingRoutes.add(assignedJob.jobId);
                  RoutingService.getRoute(
                    LatLng(trackingWorker.latitude, trackingWorker.longitude),
                    LatLng(assignedJob.latitude, assignedJob.longitude),
                  ).then((route) {
                    if (mounted) setState(() { _activeRoutes[assignedJob!.jobId] = route; _fetchingRoutes.remove(assignedJob!.jobId); });
                  });
                }
              }
            }

            final routeForJob = (assignedJob != null && _activeRoutes.containsKey(assignedJob.jobId))
                ? _activeRoutes[assignedJob.jobId]!
                : null;

            return Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(centerLat, centerLon),
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.kaamkhoj_v1',
                    ),
                    if (routeForJob != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(points: routeForJob, strokeWidth: 4.0, color: Colors.blueAccent),
                        ],
                      ),
                    MarkerLayer(markers: [...activeJobMarkers, ...workerMarkers, ...myMarker]),
                  ],
                ),
                if (hasAssignedJob && assignedJob != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (assignedJobs.length > 1)
                          _buildJobSwitcher(assignedJobs, assignedJob),
                        _buildOngoingWorkDashboard(assignedJob, isWorker: false, auth: auth),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // ── WORKER view: shows job pins ───────────────────────────────────────────
  Widget _buildWorkerMapView(
      double centerLat, double centerLon, LocationProvider location, AuthProvider auth) {
    return StreamBuilder<List<JobModel>>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('assignedWorkerUid', isEqualTo: auth.user!.uid)
          .where('status', isEqualTo: 'assigned')
          .snapshots()
          .map((snap) => snap.docs.map((doc) => JobModel.fromMap(doc.data(), doc.id)).toList()),
      builder: (context, assignedSnapshot) {
        final assignedJobs = assignedSnapshot.data ?? [];
        final hasAssignedJob = assignedJobs.isNotEmpty;
        
        JobModel? assignedJob;
        if (hasAssignedJob) {
          if (_selectedAssignedJobId != null) {
            assignedJob = assignedJobs.where((j) => j.jobId == _selectedAssignedJobId).firstOrNull ?? assignedJobs.first;
          } else {
            assignedJob = assignedJobs.first;
          }
        }

        // Track ongoing job state for button positioning
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_hasOngoingJob != hasAssignedJob && mounted) {
            setState(() { _hasOngoingJob = hasAssignedJob; });
          }
        });

        // Clean up stale routes when job completes/cancels
        if (!hasAssignedJob && _activeRoutes.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() { _activeRoutes.clear(); _fetchingRoutes.clear(); });
          });
        }

        return StreamBuilder<List<JobModel>>(
          stream: hasAssignedJob
              ? const Stream.empty()
              : FirebaseFirestore.instance
                  .collection('jobs')
                  .where('status', isEqualTo: 'open')
                  .snapshots()
                  .map((snap) => snap.docs
                      .map((doc) => JobModel.fromMap(doc.data(), doc.id))
                      .toList()),
          builder: (context, snapshot) {
            final openJobs = snapshot.data ?? [];
            // When assigned: only show that ONE job pin. Otherwise: show all open jobs.
            final jobsToDisplay = hasAssignedJob ? [assignedJob!] : openJobs;
            final jobMarkers = _buildJobMarkers(
              jobsToDisplay, 
              assignedJobIds: hasAssignedJob ? {assignedJob!.jobId} : {},
            );
            final myMarker = _myLocationMarker(location);

            // Route from worker's location to their single assigned job
            if (hasAssignedJob && assignedJob != null && location.hasLocation) {
              if (!_activeRoutes.containsKey(assignedJob.jobId) && !_fetchingRoutes.contains(assignedJob.jobId)) {
                _fetchingRoutes.add(assignedJob.jobId);
                RoutingService.getRoute(
                  LatLng(location.latitude, location.longitude),
                  LatLng(assignedJob.latitude, assignedJob.longitude),
                ).then((route) {
                  if (mounted) setState(() { _activeRoutes[assignedJob!.jobId] = route; _fetchingRoutes.remove(assignedJob!.jobId); });
                });
              }
            }

            final routeForJob = (assignedJob != null && _activeRoutes.containsKey(assignedJob.jobId))
                ? _activeRoutes[assignedJob.jobId]!
                : null;

            return Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(centerLat, centerLon),
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.kaamkhoj_v1',
                    ),
                    if (routeForJob != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(points: routeForJob, strokeWidth: 4.0, color: Colors.blueAccent),
                        ],
                      ),
                    MarkerLayer(markers: [...jobMarkers, ...myMarker]),
                  ],
                ),
                if (hasAssignedJob && assignedJob != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (assignedJobs.length > 1)
                          _buildJobSwitcher(assignedJobs, assignedJob),
                        _buildOngoingWorkDashboard(assignedJob, isWorker: true, auth: auth),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      }
    );
  }

  Widget _buildJobSwitcher(List<JobModel> jobs, JobModel currentJob) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          final isSelected = job.jobId == currentJob.jobId;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(job.title),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedAssignedJobId = job.jobId);
                }
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOngoingWorkDashboard(JobModel job, {required bool isWorker, required AuthProvider auth}) {
    final iMarkedComplete = isWorker ? job.workerCompleted : job.clientCompleted;
    final otherMarkedComplete = isWorker ? job.clientCompleted : job.workerCompleted;
    final completeField = isWorker ? 'workerCompleted' : 'clientCompleted';
    final otherUid = isWorker ? job.clientUid : (job.assignedWorkerUid ?? '');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Work Ongoing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(job.title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
              if (iMarkedComplete)
                const Chip(
                  label: Text('Waiting for partner...', style: TextStyle(fontSize: 12, color: Colors.white)),
                  backgroundColor: AppColors.warning,
                )
            ],
          ),
          const SizedBox(height: 16),
          
          if (otherUid.isNotEmpty)
            UserDetailsCard(uid: otherUid, isWorker: isWorker),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          otherUid: isWorker ? job.clientUid : job.assignedWorkerUid!,
                          otherName: isWorker ? job.clientName : 'Worker',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: iMarkedComplete ? null : () async {
                    try {
                      final updates = <String, dynamic>{
                        completeField: true,
                      };
                      if (otherMarkedComplete) {
                        updates['status'] = 'completed';
                        updates['completedAt'] = DateTime.now().toIso8601String();
                      }
                      await FirebaseFirestore.instance.collection('jobs').doc(job.jobId).update(updates);
                      if (mounted) {
                        setState(() {
                          _activeRoutes.remove(job.jobId);
                        });
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(iMarkedComplete ? 'Waiting' : 'Finish Work'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(isWorker ? 'Unassign Job?' : 'Cancel Job?'),
                    content: Text(isWorker 
                        ? 'Are you sure you want to drop this job? It will be made available for other workers.'
                        : 'Are you sure you want to cancel this ongoing job?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes', style: TextStyle(color: AppColors.error))),
                    ],
                  ),
                );
                if (confirm == true) {
                  final updateData = isWorker
                      ? <String, dynamic>{
                          'status': 'open',
                          'assignedWorkerUid': FieldValue.delete(),
                          'startedAt': FieldValue.delete(),
                          'workerCompleted': false,
                          'clientCompleted': false,
                        }
                      : <String, dynamic>{
                          'status': 'cancelled',
                        };
                        
                  await FirebaseFirestore.instance.collection('jobs').doc(job.jobId).update(updateData);
                  if (mounted) {
                    setState(() {
                      _activeRoutes.remove(job.jobId);
                    });
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(isWorker ? 'Drop Job' : 'Cancel Job'),
            ),
          ),
        ],
      ),
    );
  }


  List<Marker> _myLocationMarker(LocationProvider location) {
    if (!location.hasLocation) return [];
    return [
      Marker(
        point: LatLng(location.latitude, location.longitude),
        width: 36,
        height: 36,
        child: const Icon(Icons.my_location, color: Colors.blue, size: 32),
      )
    ];
  }

  Widget _buildDrawer(AuthProvider auth) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 220,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.textLight,
                      backgroundImage: auth.user?.profileImage != null
                          ? profileImageProvider(auth.user!.profileImage!)!
                          : null,
                      child: auth.user?.profileImage == null
                          ? const Icon(Icons.person, size: 36, color: AppColors.primary)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        auth.user?.name ?? 'User',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          auth.isWorker ? 'Worker' : 'Client',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.user?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            color: AppColors.primary.withValues(alpha: 0.1),
            child: ListTile(
              leading: const Icon(Icons.map_outlined, color: AppColors.primary),
              title: const Text('Map View', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              onTap: () => Navigator.pop(context),
            ),
          ),
          if (!auth.isWorker) ...[
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Browse Workers', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WorkerListScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.work_outline),
              title: const Text('My Jobs', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChatListScreen()));
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.work_outline),
              title: const Text('Browse Jobs', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const JobListScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WorkerSelfProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.business_center_outlined),
              title: const Text('My Jobs', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChatListScreen()));
              },
            ),
          ],
          const Divider(),
          FutureBuilder<bool>(
            future: BiometricService.instance.isBiometricEnabled().then((enabled) async {
              if (!enabled) return false;
              final saved = await BiometricService.instance.getSavedCredentials();
              return saved?.email == auth.user?.email;
            }),
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('Fingerprint Login', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.toggle_on, color: AppColors.primary, size: 36),
                onTap: () async {
                  await BiometricService.instance.clearCredentials();
                  if (!mounted) return;
                  setState(() {});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fingerprint login removed.')),
                  );
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            onTap: () async {
              await auth.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
    );
  }
}

class UserDetailsCard extends StatefulWidget {
  final String uid;
  final bool isWorker;

  const UserDetailsCard({super.key, required this.uid, required this.isWorker});

  @override
  State<UserDetailsCard> createState() => _UserDetailsCardState();
}

class _UserDetailsCardState extends State<UserDetailsCard> {
  late Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
  }

  @override
  void didUpdateWidget(covariant UserDetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _userFuture = FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();
        
        final roleLabel = widget.isWorker ? 'Client' : 'Worker';
        final name = data['name'] ?? 'Unknown';
        final email = data['email'] ?? 'No email';
        final roleColor = widget.isWorker ? Colors.blue : Colors.green;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: roleColor.withValues(alpha: 0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$roleLabel: $name', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}