import 'package:flutter/material.dart';

/// Brand color tokens, mirroring the `:root` block in `src/index.css`.
class FcColors {
  const FcColors._();

  static const Color navy = Color(0xFF0A1128);
  static const Color slate = Color(0xFF1E2749);
  static const Color ink = Color(0xFFFFFFFF);
  static const Color green = Color(0xFF00B559);
  static const Color greenDark = Color(0xFF008F47);
  static const Color red = Color(0xFFE63946);
  static const Color gold = Color(0xFFFFD60A);
  static const Color gray = Color(0xFF778DA9);
  static const Color mutedGold = Color(0xFFC9A648);

  // Light theme overrides for `[data-theme="light"]`.
  static const Color lightNavy = Color(0xFFFFFFFF);
  static const Color lightSlate = Color(0xFFF8F9FA);
  static const Color lightInk = Color(0xFF0A1128);
  static const Color lightGray = Color(0x801E2749);
}

/// The token set a theme is built from. Dark and light differ only by values.
@immutable
class FcColorTokens {
  const FcColorTokens({
    required this.surface,
    required this.elevatedSurface,
    required this.onSurface,
    required this.muted,
  });

  final Color surface;
  final Color elevatedSurface;
  final Color onSurface;
  final Color muted;

  static const FcColorTokens dark = FcColorTokens(
    surface: FcColors.navy,
    elevatedSurface: FcColors.slate,
    onSurface: FcColors.ink,
    muted: FcColors.gray,
  );

  static const FcColorTokens light = FcColorTokens(
    surface: FcColors.lightNavy,
    elevatedSurface: FcColors.lightSlate,
    onSurface: FcColors.lightInk,
    muted: FcColors.lightGray,
  );
}
