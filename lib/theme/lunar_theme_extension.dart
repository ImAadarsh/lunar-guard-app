import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic colors that adapt between light and dark mode.
@immutable
class LunarThemeColors extends ThemeExtension<LunarThemeColors> {
  const LunarThemeColors({
    required this.tileBackground,
    required this.mutedText,
    required this.border,
    required this.iconMuted,
    required this.heroGradientStart,
    required this.heroGradientEnd,
    required this.heroIconBackground,
    required this.heroIconColor,
    required this.highlightSurface,
    required this.scanPanelBackground,
    required this.scanFrame,
    required this.linkColor,
  });

  final Color tileBackground;
  final Color mutedText;
  final Color border;
  final Color iconMuted;
  final Color heroGradientStart;
  final Color heroGradientEnd;
  final Color heroIconBackground;
  final Color heroIconColor;
  final Color highlightSurface;
  final Color scanPanelBackground;
  final Color scanFrame;
  final Color linkColor;

  static const dark = LunarThemeColors(
    tileBackground: AppColors.surfaceElevated,
    mutedText: AppColors.silverMuted,
    border: AppColors.outline,
    iconMuted: AppColors.silver,
    heroGradientStart: AppColors.surfaceElevated,
    heroGradientEnd: Color(0xFF1A4A5C),
    heroIconBackground: Color(0x661A4A5C),
    heroIconColor: AppColors.onDark,
    highlightSurface: Color(0x331A4A5C),
    scanPanelBackground: AppColors.surface,
    scanFrame: Color(0x40C5D1D4),
    linkColor: AppColors.silver,
  );

  static const light = LunarThemeColors(
    tileBackground: Colors.white,
    mutedText: Color(0xFF64748B),
    border: Color(0xFFE2E8F0),
    iconMuted: Color(0xFF475569),
    heroGradientStart: Colors.white,
    heroGradientEnd: Color(0xFFE8F2F5),
    heroIconBackground: Color(0xFFDCEEF3),
    heroIconColor: AppColors.primary,
    highlightSurface: Color(0xFFF0F7FA),
    scanPanelBackground: Color(0xFFF8FAFB),
    scanFrame: Color(0xFFCBD5E1),
    linkColor: AppColors.primary,
  );

  @override
  LunarThemeColors copyWith({
    Color? tileBackground,
    Color? mutedText,
    Color? border,
    Color? iconMuted,
    Color? heroGradientStart,
    Color? heroGradientEnd,
    Color? heroIconBackground,
    Color? heroIconColor,
    Color? highlightSurface,
    Color? scanPanelBackground,
    Color? scanFrame,
    Color? linkColor,
  }) {
    return LunarThemeColors(
      tileBackground: tileBackground ?? this.tileBackground,
      mutedText: mutedText ?? this.mutedText,
      border: border ?? this.border,
      iconMuted: iconMuted ?? this.iconMuted,
      heroGradientStart: heroGradientStart ?? this.heroGradientStart,
      heroGradientEnd: heroGradientEnd ?? this.heroGradientEnd,
      heroIconBackground: heroIconBackground ?? this.heroIconBackground,
      heroIconColor: heroIconColor ?? this.heroIconColor,
      highlightSurface: highlightSurface ?? this.highlightSurface,
      scanPanelBackground: scanPanelBackground ?? this.scanPanelBackground,
      scanFrame: scanFrame ?? this.scanFrame,
      linkColor: linkColor ?? this.linkColor,
    );
  }

  @override
  LunarThemeColors lerp(ThemeExtension<LunarThemeColors>? other, double t) {
    if (other is! LunarThemeColors) return this;
    return LunarThemeColors(
      tileBackground: Color.lerp(tileBackground, other.tileBackground, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      border: Color.lerp(border, other.border, t)!,
      iconMuted: Color.lerp(iconMuted, other.iconMuted, t)!,
      heroGradientStart:
          Color.lerp(heroGradientStart, other.heroGradientStart, t)!,
      heroGradientEnd: Color.lerp(heroGradientEnd, other.heroGradientEnd, t)!,
      heroIconBackground:
          Color.lerp(heroIconBackground, other.heroIconBackground, t)!,
      heroIconColor: Color.lerp(heroIconColor, other.heroIconColor, t)!,
      highlightSurface:
          Color.lerp(highlightSurface, other.highlightSurface, t)!,
      scanPanelBackground:
          Color.lerp(scanPanelBackground, other.scanPanelBackground, t)!,
      scanFrame: Color.lerp(scanFrame, other.scanFrame, t)!,
      linkColor: Color.lerp(linkColor, other.linkColor, t)!,
    );
  }
}

extension LunarThemeContext on BuildContext {
  LunarThemeColors get lunar =>
      Theme.of(this).extension<LunarThemeColors>() ?? LunarThemeColors.dark;

  ColorScheme get cs => Theme.of(this).colorScheme;
}
