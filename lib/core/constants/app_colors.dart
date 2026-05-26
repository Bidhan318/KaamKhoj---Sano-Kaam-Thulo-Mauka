// lib/core/constants/app_colors.dart
//
// PURPOSE: Central color palette for KaamKhoj.
// All colors used across the app are defined here so changing the
// brand color only requires editing this one file.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Brand Colors ---
  static const Color primary = Color(0xFF0F3460);        // Deep indigo
  static const Color primaryDark = Color(0xFF0A2340);    // Darker indigo for pressed states
  static const Color accent = Color(0xFFFFA000);         // Amber – keep same, works well

  // --- Gradient (use these for AppBar, buttons, splash) ---
  static const Color gradientStart = Color(0xFF1A1A2E);  // Deep dark indigo
  static const Color gradientEnd = Color(0xFF16C79A);    // Teal green

  // --- Background ---
  static const Color background = Color(0xFF0F0F1A);     // Dark background
  static const Color surface = Color(0xFF1A1A2E);        // Card / bottom sheet surface

  // --- Text ---
  static const Color textPrimary = Color(0xFFEEEEEE);    // Light text on dark bg
  static const Color textSecondary = Color(0xFF9E9E9E);  // Muted / caption text
  static const Color textLight = Color(0xFFFFFFFF);      // Text on dark backgrounds

  // --- Status Colors ---
  static const Color success = Color(0xFF16C79A);        // Teal – available / posted
  static const Color error = Color(0xFFE53935);          // Keep same
  static const Color warning = Color(0xFFFB8C00);        // Keep same

  // --- Misc ---
  static const Color divider = Color(0xFF2A2A3E);        // Dark divider
  static const Color mapMarkerClient = Color(0xFF16C79A); // Teal markers
  static const Color mapMarkerWorker = Color(0xFFE53935); // Red markers
}