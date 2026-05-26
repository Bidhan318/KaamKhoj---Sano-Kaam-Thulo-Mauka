// lib/core/constants/app_colors.dart
//
// PURPOSE: Central color palette for KaamKhoj.
// All colors used across the app are defined here so changing the
// brand color only requires editing this one file.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Prevent instantiation

  // --- Brand Colors ---
  static const Color primary = Color(0xFF1A73E8);       // Blue – main action color
  static const Color primaryDark = Color(0xFF0D47A1);   // Darker blue for pressed states
  static const Color accent = Color(0xFFFFA000);         // Amber – highlights, badges, ratings

  // --- Background ---
  static const Color background = Color(0xFFF5F7FA);    // Light grey app background
  static const Color surface = Color(0xFFFFFFFF);       // Card / bottom sheet surface

  // --- Text ---
  static const Color textPrimary = Color(0xFF212121);   // Dark text
  static const Color textSecondary = Color(0xFF757575); // Muted / caption text
  static const Color textLight = Color(0xFFFFFFFF);     // Text on dark backgrounds

  // --- Status Colors ---
  static const Color success = Color(0xFF43A047);       // Worker available / job posted
  static const Color error = Color(0xFFE53935);         // Errors, unavailable
  static const Color warning = Color(0xFFFB8C00);       // Pending states

  // --- Misc ---
  static const Color divider = Color(0xFFE0E0E0);
  static const Color mapMarkerClient = Color(0xFF1A73E8);
  static const Color mapMarkerWorker = Color(0xFFE53935);
}