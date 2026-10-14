import 'package:flutter/material.dart';

/// Single source of truth for raw hex color palettes.
abstract final class AppColors {
  // Brand Core
  static const Color primarySeed = Color(0xFF1E56A0);
  static const Color secondarySeed = Color(0xFF00B4D8);
  static const Color tertiarySeed = Color(0xFFFF9F1C);

  // ---------------------------------------------------------------------------
  // LIGHT PALETTE
  // ---------------------------------------------------------------------------
  static const Color lightPrimary = Color(0xFF1E56A0);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFD6E4FF);
  static const Color lightOnPrimaryContainer = Color(0xFF001A40);

  static const Color lightSecondary = Color(0xFF007799);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightSecondaryContainer = Color(0xFFC7E7F5);
  static const Color lightOnSecondaryContainer = Color(0xFF001F29);

  static const Color lightTertiary = Color(0xFF8B5000);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightTertiaryContainer = Color(0xFFFFDCBE);
  static const Color lightOnTertiaryContainer = Color(0xFF2C1600);

  static const Color lightSurface = Color(0xFFF9F9FC);
  static const Color lightOnSurface = Color(0xFF1A1C1E);
  static const Color lightSurfaceDim = Color(0xFFD9DADC);
  static const Color lightSurfaceBright = Color(0xFFFDFDFD);

  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLow = Color(0xFFF3F3F7);
  static const Color lightSurfaceContainer = Color(0xFFEDEEF2);
  static const Color lightSurfaceContainerHigh = Color(0xFFE7E8EC);
  static const Color lightSurfaceContainerHighest = Color(0xFFE1E2E6);

  static const Color lightOutline = Color(0xFF73777F);
  static const Color lightOutlineVariant = Color(0xFFC3C7D0);

  // ---------------------------------------------------------------------------
  // DARK PALETTE
  // ---------------------------------------------------------------------------
  static const Color darkPrimary = Color(0xFFA8C7FA);
  static const Color darkOnPrimary = Color(0xFF002E69);
  static const Color darkPrimaryContainer = Color(0xFF004494);
  static const Color darkOnPrimaryContainer = Color(0xFFD6E4FF);

  static const Color darkSecondary = Color(0xFF7CD4F7);
  static const Color darkOnSecondary = Color(0xFF003544);
  static const Color darkSecondaryContainer = Color(0xFF004D63);
  static const Color darkOnSecondaryContainer = Color(0xFFC7E7F5);

  static const Color darkTertiary = Color(0xFFFFB878);
  static const Color darkOnTertiary = Color(0xFF4A2800);
  static const Color darkTertiaryContainer = Color(0xFF693C00);
  static const Color darkOnTertiaryContainer = Color(0xFFFFDCBE);

  static const Color darkSurface = Color(0xFF111318);
  static const Color darkOnSurface = Color(0xFFE2E2E6);
  static const Color darkSurfaceDim = Color(0xFF111318);
  static const Color darkSurfaceBright = Color(0xFF37393E);

  static const Color darkSurfaceContainerLowest = Color(0xFF0C0E13);
  static const Color darkSurfaceContainerLow = Color(0xFF191C20);
  static const Color darkSurfaceContainer = Color(0xFF1E2025);
  static const Color darkSurfaceContainerHigh = Color(0xFF282A2F);
  static const Color darkSurfaceContainerHighest = Color(0xFF33353A);

  static const Color darkOutline = Color(0xFF8D9199);
  static const Color darkOutlineVariant = Color(0xFF43474E);

  // ---------------------------------------------------------------------------
  // SEMANTIC & STATUS COLORS
  // ---------------------------------------------------------------------------
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);
  static const Color darkErrorContainer = Color(0xFF93000A);
  static const Color darkOnErrorContainer = Color(0xFFFFDAD6);

  static const Color success = Color(0xFF2E7D32);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFED6C02);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color info = Color(0xFF0288D1);
  static const Color onInfo = Color(0xFFFFFFFF);

  // Common Utilities
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerDarkBase = Color(0xFF2A2D34);
  static const Color shimmerDarkHighlight = Color(0xFF3E424C);
}
