// lib/core/constants/app_theme.dart
<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
=======
//
// PURPOSE: Defines the MaterialTheme used throughout the app.
// Centralizing theme here means UI consistency is enforced automatically
// – no need to set colors manually on each widget.

import 'package:flutter/material.dart';
import 'app_colors.dart';
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
<<<<<<< HEAD
      colorScheme: ColorScheme.light(
        primary:     AppColors.primary,
        secondary:   AppColors.secondary,
        surface:     AppColors.surface,
        error:       AppColors.error,
        onPrimary:   AppColors.textLight,
        onSecondary: AppColors.textLight,
        onSurface:   AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // ── AppBar ────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation:       0,
        centerTitle:     false,
        titleTextStyle: TextStyle(
          color:         AppColors.textLight,
          fontSize:      20,
          fontWeight:    FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.textLight),
      ),

      // ── Elevated Button ───────────────────────────────────────────
=======
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      // Scaffold background (the grey behind all screens)
      scaffoldBackgroundColor: AppColors.background,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textLight,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ElevatedButton (primary action buttons like "Hire Now", "Post Job")
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
<<<<<<< HEAD
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize:      15,
            fontWeight:    FontWeight.w700,
            letterSpacing: 0.3,
=======
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
          ),
        ),
      ),

<<<<<<< HEAD
      // ── Outlined Button ───────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondary,
          side: const BorderSide(color: AppColors.secondary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          textStyle: const TextStyle(
            fontSize:   15,
            fontWeight: FontWeight.w600,
=======
      // OutlinedButton (secondary actions like "Message")
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
          ),
        ),
      ),

<<<<<<< HEAD
      // ── Text Button ───────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize:   14,
          ),
        ),
      ),

      // ── Input Fields ──────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: AppColors.surface,
        hintStyle:  const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // ── Cards ─────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:     AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),

      // ── Chips ─────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE8EAF6),
        labelStyle: const TextStyle(
          color:      AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize:   12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textLight,
        elevation:       4,
      ),

      // ── TabBar ────────────────────────────────────────────────────
      tabBarTheme: const TabBarThemeData(
        labelColor:          AppColors.secondary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor:      AppColors.secondary,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontSize: 14),
      ),

      // ── Bottom Sheet ──────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ── Drawer ────────────────────────────────────────────────────
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surface,
      ),

      // ── Divider ───────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color:     AppColors.divider,
        thickness: 1,
        space:     1,
      ),

      // ── SnackBar ──────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ── Icon ──────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
      ),

      // ── Text ──────────────────────────────────────────────────────
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
  headlineMedium: GoogleFonts.outfit(
    color:         AppColors.textPrimary,
    fontWeight:    FontWeight.bold,
    fontSize:      24,
    letterSpacing: 0.2,
  ),
  headlineSmall: GoogleFonts.outfit(
    color:      AppColors.textPrimary,
    fontWeight: FontWeight.bold,
    fontSize:   20,
  ),
  titleLarge: GoogleFonts.outfit(
    color:      AppColors.textPrimary,
    fontWeight: FontWeight.w600,
    fontSize:   18,
  ),
  titleMedium: GoogleFonts.outfit(
    color:      AppColors.textPrimary,
    fontWeight: FontWeight.w500,
    fontSize:   16,
  ),
  bodyLarge: GoogleFonts.inter(
    color:    AppColors.textPrimary,
    fontSize: 16,
  ),
  bodyMedium: GoogleFonts.inter(
    color:    AppColors.textPrimary,
    fontSize: 14,
  ),
  bodySmall: GoogleFonts.inter(
    color:    AppColors.textSecondary,
    fontSize: 12,
  ),
  labelLarge: GoogleFonts.inter(
    color:      AppColors.textPrimary,
    fontWeight: FontWeight.w600,
    fontSize:   14,
  ),
),//textTheme
=======
      // Input fields (phone, job title, description, etc.)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Cards (worker cards, job cards)
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Chip (skill tags on worker profiles)
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),

      dividerColor: AppColors.divider,

      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
    );
  }
}