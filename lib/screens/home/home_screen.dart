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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

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
  List<Marker> _buildJobMarkers(List<JobModel> jobs) {
    return jobs.map((job) {
      if (job.latitude == 0 && job.longitude == 0) return null;
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
                  border: Border.all(color: Colors.orange, width: 3),
                  color: Colors.white,
                ),
                child: const Icon(Icons.work, color: Colors.orange),
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
              ? _buildWorkerMapView(centerLat, centerLon, location)
              : _buildClientMapView(centerLat, centerLon, location, workerProvider),

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
            bottom: 24,
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
      LocationProvider location, WorkerProvider workerProvider) {
    return StreamBuilder<List<WorkerModel>>(
      stream: location.hasLocation
          ? workerProvider.watchNearbyWorkers(
              clientLat: location.latitude,
              clientLon: location.longitude,
            )
          : const Stream.empty(),
      builder: (context, snapshot) {
        List<WorkerModel> workers = snapshot.data ?? [];
        
        // Apply skill filter locally
        final query = workerProvider.skillFilter.toLowerCase();
        if (query.isNotEmpty) {
          workers = workers.where((w) => w.skills.any((s) => s.toLowerCase().contains(query))).toList();
        }

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
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.textLight,
                  backgroundImage: auth.user?.profileImage != null
                      ? profileImageProvider(auth.user!.profileImage!)!
                      : null,
                  child: auth.user?.profileImage == null
                      ? const Icon(Icons.person, size: 32, color: AppColors.primary)
                      : null,
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
            ListTile(
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
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('My Profile'),
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
