// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Brand Gradient Colors ---
  static const Color primary       = Color(0xFF3F51B5); // Indigo – main action color
  static const Color primaryDark   = Color(0xFF283593); // Deep Indigo – pressed states
  static const Color secondary     = Color(0xFF009688); // Teal – accents, chips, icons
  static const Color secondaryDark = Color(0xFF00695C); // Deep Teal – active states
  static const Color accent        = Color(0xFFFFAB40); // Warm Amber – ratings, highlights

  // --- Gradient (for AppBar, buttons, hero sections) ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3F51B5), Color(0xFF009688)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // --- Backgrounds ---
  static const Color background = Color(0xFFF0F2F8); // Cool off-white with a blue tint
  static const Color surface    = Color(0xFFFFFFFF); // Card / sheet surface

  // --- Text ---
  static const Color textPrimary   = Color(0xFF1A1F36); // Deep navy-charcoal
  static const Color textSecondary = Color(0xFF6B7280); // Muted grey
  static const Color textLight     = Color(0xFFFFFFFF); // On dark backgrounds

  // --- Status Colors ---
  static const Color success = Color(0xFF26A69A); // Teal-ish green – available
  static const Color error   = Color(0xFFEF5350); // Soft red – errors
  static const Color warning = Color(0xFFFFA726); // Amber – pending

  // --- Misc ---
  static const Color divider         = Color(0xFFE2E6F0); // Cool-tinted divider
  static const Color mapMarkerClient = Color(0xFF3F51B5); // Indigo pin
  static const Color mapMarkerWorker = Color(0xFF009688); // Teal pin
}