// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../job/my_jobs_screen.dart';
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
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  // Default: Kathmandu
  static const double _defaultLat = 27.7172;
  static const double _defaultLon = 85.3240;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
    _loadBiometricState();
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

  Future<void> _loadBiometricState() async {
    final available = await BiometricService.instance.isBiometricAvailable();
    final enabled = await BiometricService.instance.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
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
  final user = auth.user;
  return Drawer(
    backgroundColor: AppColors.surface,
    child: Column(
      children: [
        // ── Gradient Header ───────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 24,
            bottom: 24,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3F51B5), Color(0xFF009688)], // AppColors.primaryGradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.background,
                  backgroundImage: user?.profileImage != null
                      ? profileImageProvider(user!.profileImage!)
                      : null,
                  child: user?.profileImage == null
                      ? const Icon(Icons.person,
                          size: 40, color: AppColors.textSecondary)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              // Name + Role Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      user?.name ?? 'User',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(230),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      auth.isWorker ? 'Worker' : 'Client',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Email
              Text(
                user?.email ?? '',
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        // ── Menu Items ──────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _drawerItem(
                  icon: Icons.map_outlined,
                  label: 'Map View',
                  isActive: true,
                  onTap: () => Navigator.pop(context),
                ),
                if (!auth.isWorker) ...[
                  _drawerItem(
                    icon: Icons.people_outline,
                    label: 'Browse Workers',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WorkerListScreen()),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.work_outline,
                    label: 'My Jobs',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyJobsScreen()),
                      );
                    },
                  ),
                  _buildMessagesItem(auth),
                ] else ...[
                  _drawerItem(
                    icon: Icons.work_outline,
                    label: 'Browse Jobs',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const JobListScreen()),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.person_outline,
                    label: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const WorkerSelfProfileScreen()),
                      );
                    },
                  ),
                ],

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: AppColors.divider, height: 1),
                ),

                // ── Fingerprint Toggle ──────────────────────────────────
                if (_biometricAvailable && _biometricEnabled)
                  _buildFingerprintToggle(),

                // ── Logout ──────────────────────────────────────────────
                _buildLogoutItem(auth),
              ],
            ),
          ),

      // ── Version ─────────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          'v1.0.0',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ),
    ],
  ),
);
}

Widget _drawerItem({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  bool isActive = false,
  int? badge,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    decoration: BoxDecoration(
      color:
          isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppColors.primary : AppColors.textSecondary,
        size: 22,
      ),
      title: Text(
      label,
      style: TextStyle(
        color: isActive ? AppColors.primaryDark : AppColors.textPrimary,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        fontSize: 15,
        letterSpacing: isActive ? 0.3 : 0,
      ),
    ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
      splashColor: AppColors.primary.withOpacity(0.1),
      dense: true,
      visualDensity: const VisualDensity(vertical: 0.5),
    ),
  );
}

Widget _buildMessagesItem(AuthProvider auth) {
  if (auth.user == null) {
    return _drawerItem(
      icon: Icons.chat_bubble_outline,
      label: 'Messages',
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatListScreen()),
        );
      },
    );
  }
  return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: auth.user!.uid)
        .snapshots(),
    builder: (context, snapshot) {
      int unreadCount = 0;
      if (snapshot.hasData) {
        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['lastSenderId'] != null &&
              data['lastSenderId'] != auth.user!.uid) {
            unreadCount++;
          }
        }
      }
      return _drawerItem(
        icon: Icons.chat_bubble_outline,
        label: 'Messages',
        badge: unreadCount > 0 ? unreadCount : null,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatListScreen()),
          );
        },
      );
    },
  );
}

Widget _buildFingerprintToggle() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    child: ListTile(
      leading: const Icon(
        Icons.fingerprint,
        color: AppColors.textSecondary,
        size: 22,
      ),
      title: const Text(
        'Fingerprint Login',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: Switch(
        value: _biometricEnabled,
        activeColor: AppColors.primary,
        onChanged: (value) async {
          if (!value) {
            await BiometricService.instance.clearCredentials();
            if (mounted) {
              setState(() {
                _biometricEnabled = false;
              });
            }
          }
        },
      ),
      dense: true,
      visualDensity: const VisualDensity(vertical: 0.5),
    ),
  );
}

Widget _buildLogoutItem(AuthProvider auth) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    child: ListTile(
      leading: const Icon(
        Icons.logout,
        color: AppColors.error,
        size: 22,
      ),
      title: const Text(
        'Logout',
        style: TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () async {
        await auth.signOut();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
      splashColor: AppColors.error.withOpacity(0.1),
      dense: true,
      visualDensity: const VisualDensity(vertical: 0.5),
    ),
  );
}
}
