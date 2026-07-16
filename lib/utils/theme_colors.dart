import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:flutter/material.dart';

/// Brightness-aware colors for surfaces and brand accents.
class ThemeColors {
  const ThemeColors._(this._context);

  final BuildContext _context;

  static ThemeColors of(BuildContext context) => ThemeColors._(context);

  ColorScheme get scheme => Theme.of(_context).colorScheme;

  bool get isDark => scheme.brightness == Brightness.dark;

  /// Brand accent — navy in light mode, lighter blue in dark mode.
  Color get brand => isDark ? const Color(0xFF6BA8E5) : AppColors.blue;

  /// Fixed navy for sidebar and always-dark brand surfaces.
  Color get brandNavy => AppColors.blue;

  Color get brandSoft => brand.withValues(alpha: isDark ? 0.18 : 0.08);

  Color get brandMuted => brand.withValues(alpha: isDark ? 0.28 : 0.12);

  /// High-contrast accent for loading dots and progress on dark surfaces.
  Color get loading => isDark ? const Color(0xFF9EC8F7) : brand;

  /// Shimmer skeleton colors for loading placeholders.
  Color get shimmerBase =>
      isDark ? const Color(0xFF2A2A2D) : AppColors.lightGrey.withValues(alpha: 0.35);

  Color get shimmerHighlight =>
      isDark ? const Color(0xFF3E3E42) : Colors.white;

  /// Backdrop for the dark Duoob logo asset — always light for contrast.
  Color get logoBackdrop => Colors.white;

  Color get surface => scheme.surface;

  Color get surfaceMuted =>
      isDark ? const Color(0xFF1C1C1E) : AppColors.lightBackground;

  Color get cardFill => isDark ? const Color(0xFF1C1C1E) : Colors.white;

  Color get border =>
      isDark ? const Color(0xFF3A3A3C) : AppColors.borderGrey;

  Color get textPrimary => scheme.onSurface;

  Color get textMuted => scheme.onSurfaceVariant;

  Color get iconMuted => isDark ? const Color(0xFF9E9E9E) : AppColors.iconGrey;

  Color get onBrand => Colors.white;

  Color get shadow => brand.withValues(alpha: isDark ? 0.12 : 0.06);

  Color get chatUserBubble => brand;

  Color get chatBotBubble => cardFill;
}

extension ThemeColorsContext on BuildContext {
  ThemeColors get colors => ThemeColors.of(this);
}
