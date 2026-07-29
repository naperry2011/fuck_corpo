import 'package:flutter/widgets.dart';

/// Elevation and glow tokens.
class FcShadows {
  const FcShadows._();

  static const List<BoxShadow> sm = <BoxShadow>[
    BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> md = <BoxShadow>[
    BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> lg = <BoxShadow>[
    BoxShadow(color: Color(0x4D000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// `--glow-green: 0 0 20px rgba(0,181,89,0.4)`
  static const List<BoxShadow> glowGreen = <BoxShadow>[
    BoxShadow(color: Color(0x6600B559), blurRadius: 20),
  ];
}
