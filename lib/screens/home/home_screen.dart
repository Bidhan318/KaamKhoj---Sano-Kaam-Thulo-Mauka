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
import '../worker/worker_list_screen.dart';
import '../auth/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/biometric_service.dart';
import '../chat/chat_list_screen.dart';
import '../worker/worker_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();

  // Default: Kathmandu
  static const double _defaultLat = 27.7172;
  static const double _defaultLon = 85.3240;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
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
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => _onWorkerTapped(worker),
          child: Tooltip(
            message: '${worker.name} - ${worker.skills.first}',
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4)
                    ],
                  ),
                  child: const Icon(Icons.person_pin,
                      color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // ── Job markers for WORKER view ────────────────────────────────────────────
  List<Marker> _buildJobMarkers(List<JobModel> jobs) {
    return jobs.map((job) {
      // Skip jobs with no location
      if (job.latitude == 0 && job.longitude == 0) return null;
      return Marker(
        point: LatLng(job.latitude, job.longitude),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => _onJobTapped(job),
          child: Tooltip(
            message: '${job.title} - NPR ${job.budget.toInt()}',
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 4)
                ],
              ),
              child: const Icon(Icons.work, color: Colors.white, size: 20),
            ),
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
        maxChildSize: 0.92, // CHANGED: cap at 92% instead of 1.0
        expand: false,
        // CHANGED: listen to sheet size — when dragged near top, push full profile
        builder: (_, scrollController) {
          return NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              if (notification.extent >= 0.88) {
                // CHANGED: auto-navigate to full profile when dragged high enough
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
    final isWorker = auth.isWorker;

    final centerLat = location.hasLocation ? location.latitude : _defaultLat;
    final centerLon = location.hasLocation ? location.longitude : _defaultLon;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.appName),
            if (location.currentAddress.isNotEmpty)
              Text(
                location.currentAddress,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isWorker ? Icons.work_outline : Icons.people_outline),
            tooltip: isWorker ? 'Browse Jobs' : 'Browse Workers',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => isWorker
                    ? const JobListScreen()
                    : const WorkerListScreen(),
              ),
            ),
          ),
        ],
      ),

      drawer: _buildDrawer(auth),

      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          isWorker
              ? _buildWorkerMapView(centerLat, centerLon, location)
              : _buildClientMapView(
                  centerLat, centerLon, location, workerProvider),

          // ── Loading overlay ───────────────────────────────────────────────
          if (location.isLoading)
            const Center(child: CircularProgressIndicator()),

          // ── Error banner ──────────────────────────────────────────────────
          if (location.errorMessage != null)
            Positioned(
              top: 0,
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

          // ── Legend ───────────────────────────────────────────────────────
          Positioned(
            top: location.errorMessage != null ? 48 : 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isWorker ? Icons.work : Icons.person_pin,
                    color: isWorker ? Colors.orange : AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isWorker ? 'Job posts' : 'Workers',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),

          // ── My location button ────────────────────────────────────────────
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'myLocation',
              onPressed: () async {
                await location.fetchCurrentLocation();
                if (location.hasLocation) {
                  _mapController.move(
                    LatLng(location.latitude, location.longitude),
                    14.0,
                  );
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),

      // ── FAB: Post Job for clients only ────────────────────────────────────
      floatingActionButton: isWorker
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostJobScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.postJob),
            ),
    );
  }

  // ── CLIENT view: shows worker pins ────────────────────────────────────────
  Widget _buildClientMapView(double centerLat, double centerLon,
      LocationProvider location, WorkerProvider workerProvider) {
    return StreamBuilder<List<WorkerModel>>(
      stream: location.hasLocation
          ? workerProvider.watchNearbyWorkers(
              clientLat: location.latitude,
              clientLon: location.longitude,
            )
          : const Stream.empty(),
      builder: (context, snapshot) {
        final workers = snapshot.data ?? [];
        final workerMarkers = _buildWorkerMarkers(workers);
        final myMarker = _myLocationMarker(location);

        return FlutterMap(
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
            MarkerLayer(markers: [...myMarker, ...workerMarkers]),
          ],
        );
      },
    );
  }

  // ── WORKER view: shows job pins ───────────────────────────────────────────
  Widget _buildWorkerMapView(
      double centerLat, double centerLon, LocationProvider location) {
    return StreamBuilder<List<JobModel>>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('status', isEqualTo: 'open')
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => JobModel.fromMap(doc.data(), doc.id))
              .toList()),
      builder: (context, snapshot) {
        final jobs = snapshot.data ?? [];
        final jobMarkers = _buildJobMarkers(jobs);
        final myMarker = _myLocationMarker(location);

        return FlutterMap(
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
            MarkerLayer(markers: [...myMarker, ...jobMarkers]),
          ],
        );
      },
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
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.textLight,
                  child: Icon(Icons.person, size: 32, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  auth.user?.name ?? 'User',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                Text(
                  auth.isWorker ? 'Worker' : 'Client',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Map View'),
            onTap: () => Navigator.pop(context),
          ),
          if (!auth.isWorker) ...[
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Browse Workers'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WorkerListScreen()));
              },
            ),
            ListTile(                                      // ← ADD THIS
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Messages'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChatListScreen()));
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.work_outline),
              title: const Text('Browse Jobs'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const JobListScreen()));
              },
            ),
            ListTile(                                      // ← ADD THIS
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Messages'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChatListScreen()));
              },
            ),
          ],
          const Divider(),

          //--fingerprint biometric removal option ----- DONT TOUCH
          FutureBuilder<bool>(
            future: BiometricService.instance.isBiometricEnabled().then((enabled) async {
            if (!enabled) return false;
            final saved = await BiometricService.instance.getSavedCredentials();
            return saved?.email == auth.user?.email;
            }),
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
                return ListTile(
              leading: const Icon(Icons.fingerprint, color: AppColors.error),
              title: const Text('Remove Fingerprint Login',
              style: TextStyle(color: AppColors.error)),
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
//--------------------------------------------------------------------------------
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout',
                style: TextStyle(color: AppColors.error)),
            onTap: () async {
              await auth.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
    );
  }
}

// ── Job List Screen (for Workers) ─────────────────────────────────────────────
class JobListScreen extends StatelessWidget {
  const JobListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Jobs')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('status', isEqualTo: 'open')
            .orderBy('postedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work_off, size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('No open jobs yet',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          final jobs = snapshot.data!.docs
              .map((doc) =>
                  JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jobs.length,
            itemBuilder: (context, i) => _JobCard(job: jobs[i]),
          );
        },
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(job.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'OPEN',
                      style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.build_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(job.requiredSkill,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 16),
                  const Icon(Icons.currency_rupee,
                      size: 14, color: AppColors.textSecondary),
                  Text('${job.budget.toInt()}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                job.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(job.clientName,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}