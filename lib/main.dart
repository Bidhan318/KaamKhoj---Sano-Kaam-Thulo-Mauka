// lib/main.dart
//
// PURPOSE: App entry point.
// Initializes Firebase, sets up all Provider instances at the root,
// and launches SplashScreen which handles the auth routing.
//
// Provider tree:
//   AuthProvider     → who is logged in, their role
//   LocationProvider → current GPS position
//   WorkerProvider   → nearby workers list & selected worker state

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/worker_provider.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  // Required before any async work in main()
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (requires google-services.json on Android /
  // GoogleService-Info.plist on iOS to be configured)
  await Firebase.initializeApp();

  runApp(const KaamKhojApp());
}

class KaamKhojApp extends StatelessWidget {
  const KaamKhojApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthProvider: manages login state, current user, OTP flow
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // LocationProvider: GPS position for the client/worker
        ChangeNotifierProvider(create: (_) => LocationProvider()),

        // WorkerProvider: nearby workers, filtering, selected worker
        ChangeNotifierProvider(create: (_) => WorkerProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(), // Auth routing is handled inside SplashScreen
      ),
    );
  }
}

