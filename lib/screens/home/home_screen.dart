// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/worker_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/worker_provider.dart';
import '../../widgets/bottom_sheet_worker.dart';
import '../job/post_job_screen.dart';
import '../worker/worker_list_screen.dart';
import '../auth/login_screen.dart';

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

  List<Marker> _buildMarkers(List<WorkerModel> workers) {
    return workers.map((worker) {
      return Marker(
        point: LatLng(worker.latitude, worker.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _onWorkerMarkerTapped(worker),
          child: Tooltip(
            message: worker.name,
            child: const Icon(
              Icons.location_pin,
              color: Colors.red,
              size: 40,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _onWorkerMarkerTapped(WorkerModel worker) {
    context.read<WorkerProvider>().selectWorker(worker);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BottomSheetWorker(worker: worker),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();
    final auth = context.watch<AuthProvider>();
    final workerProvider = context.watch<WorkerProvider>();

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
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filter workers',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkerListScreen()),
            ),
          ),
        ],
      ),

      drawer: _buildDrawer(auth),

      body: Stack(
        children: [
          // ── flutter_map ────────────────────────────────────────────────────
          StreamBuilder<List<WorkerModel>>(
            stream: location.hasLocation
                ? workerProvider.watchNearbyWorkers(
                    clientLat: location.latitude,
                    clientLon: location.longitude,
                  )
                : const Stream.empty(),
            builder: (context, snapshot) {
              final workers = snapshot.data ?? [];
              final workerMarkers = _buildMarkers(workers);

              // My location marker
              final myMarker = location.hasLocation
                  ? [
                      Marker(
                        point: LatLng(location.latitude, location.longitude),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 32,
                        ),
                      )
                    ]
                  : <Marker>[];

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(centerLat, centerLon),
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.kaamkhoj_v1',
                  ),
                  MarkerLayer(markers: [...myMarker, ...workerMarkers]),
                ],
              );
            },
          ),

          // ── Loading overlay ────────────────────────────────────────────────
          if (location.isLoading)
            const Center(child: CircularProgressIndicator()),

          // ── Location error banner ──────────────────────────────────────────
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

          // ── My location button ─────────────────────────────────────────────
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

      // ── FAB: Post a Job (clients only) ─────────────────────────────────────
      floatingActionButton: auth.isWorker
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
                  auth.user?.role == 'worker' ? 'Worker' : 'Client',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Map View'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Browse Workers'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WorkerListScreen()));
            },
          ),
          const Divider(),
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