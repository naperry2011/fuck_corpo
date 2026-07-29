import 'package:flutter/material.dart';

import 'colors.dart';
import 'radii.dart';
import 'typography.dart';

/// Builds the FuckCorpo [ThemeData] from a single token set, so dark and light
/// never drift apart.
ThemeData buildFcTheme(FcColorTokens tokens, Brightness brightness) {
  final ColorScheme scheme = ColorScheme(
    brightness: brightness,
    primary: FcColors.green,
    onPrimary: FcColors.navy,
    secondary: FcColors.gold,
    onSecondary: FcColors.navy,
    error: FcColors.red,
    onError: FcColors.ink,
    surface: tokens.surface,
    onSurface: tokens.onSurface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: tokens.surface,
    canvasColor: tokens.surface,
    textTheme: FcText.buildTextTheme(tokens.onSurface, tokens.muted),
    cardTheme: CardThemeData(
      color: tokens.elevatedSurface,
      shape: const RoundedRectangleBorder(borderRadius: FcRadii.lg),
    ),
    dividerColor: tokens.muted,
  );
}

ThemeData buildDarkTheme() => buildFcTheme(FcColorTokens.dark, Brightness.dark);

ThemeData buildLightTheme() =>
    buildFcTheme(FcColorTokens.light, Brightness.light);
