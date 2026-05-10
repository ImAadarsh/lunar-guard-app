import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

ThemeData buildLunarTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onDark,
      secondary: AppColors.silver,
      onSecondary: AppColors.primaryDark,
      surface: AppColors.surface,
      onSurface: AppColors.onDark,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.outline,
    ),
    scaffoldBackgroundColor: AppColors.primaryDark,
    appBarTheme: AppBarThemeData(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: AppColors.onDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onDark,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline, width: 1),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.primaryDark,
      indicatorColor: AppColors.primary.withValues(alpha: 0.45),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.onDark
              : AppColors.silverMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.onDark
              : AppColors.silverMuted,
          size: 24,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.silver, width: 1.5),
      ),
      labelStyle: GoogleFonts.inter(color: AppColors.silverMuted),
      hintStyle: GoogleFonts.inter(
          color: AppColors.silverMuted.withValues(alpha: 0.7)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
  );

  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.onDark,
      displayColor: AppColors.onDark,
    ),
  );
}
