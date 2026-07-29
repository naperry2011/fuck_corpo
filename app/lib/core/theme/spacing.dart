/// 8pt spacing scale, in logical pixels, from the CSS rem scale at a 16px root.
class FcSpacing {
  const FcSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double s = 16;
  static const double m = 24;
  static const double l = 32;
  static const double xl = 48;
  static const double xxl = 64;
  static const double xxxl = 96;
}

/// Layout width constraints from `--max-width` and friends.
class FcLayout {
  const FcLayout._();

  static const double maxWidth = 1400;
  static const double contentWidth = 1200;
  static const double narrowWidth = 800;
  static const double cardMaxWidth = 600;
}

/// Responsive breakpoints.
class FcBreakpoints {
  const FcBreakpoints._();

  static const double mobile = 320;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double wide = 1440;
}
