import 'package:flutter/material.dart';

/// Font families. The binaries are self-hosted under `assets/fonts/` and
/// declared in `pubspec.yaml`, so the app renders the brand faces offline and
/// never reaches out to Google Fonts at runtime. `test/core/theme/fonts_test.dart`
/// fails if a family named here stops being bundled.
class FcFonts {
  const FcFonts._();

  static const String display = 'Playfair Display';
  static const String body = 'Work Sans';
  static const String mono = 'Roboto Mono';
}

/// Text tokens. Every number in the app uses [mono].
class FcText {
  const FcText._();

  static const TextStyle mono = TextStyle(
    fontFamily: FcFonts.mono,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static TextTheme buildTextTheme(Color onSurface, Color muted) {
    TextStyle display(double size, FontWeight weight) => TextStyle(
      fontFamily: FcFonts.display,
      fontSize: size,
      fontWeight: weight,
      color: onSurface,
    );
    TextStyle body(double size, FontWeight weight, Color color) => TextStyle(
      fontFamily: FcFonts.body,
      fontSize: size,
      fontWeight: weight,
      color: color,
    );

    return TextTheme(
      displayLarge: display(57, FontWeight.w900),
      displayMedium: display(45, FontWeight.w900),
      displaySmall: display(36, FontWeight.w700),
      headlineLarge: display(32, FontWeight.w700),
      headlineMedium: display(28, FontWeight.w700),
      headlineSmall: display(24, FontWeight.w700),
      titleLarge: body(22, FontWeight.w600, onSurface),
      titleMedium: body(16, FontWeight.w600, onSurface),
      titleSmall: body(14, FontWeight.w600, onSurface),
      bodyLarge: body(16, FontWeight.w400, onSurface),
      bodyMedium: body(14, FontWeight.w400, onSurface),
      bodySmall: body(12, FontWeight.w400, muted),
      labelLarge: body(14, FontWeight.w600, onSurface),
      labelMedium: body(12, FontWeight.w500, muted),
      labelSmall: body(11, FontWeight.w500, muted),
    );
  }
}
