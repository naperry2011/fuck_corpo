import 'package:flutter/painting.dart';

import '../../core/theme/colors.dart';

/// Single owner of category label, emoji and chart color.
///
/// React split these across `Timer.jsx` (value + emoji) and `Dashboard.jsx`
/// (color, keyed by a different set of strings), which is why three of the five
/// doughnut wedges rendered gray. Keeping one enum removes that class of bug.
enum BreakCategory {
  bathroom('Bathroom', '\u{1F6BD}', FcColors.green),
  smokeBreak('Smoke Break', '\u{1F6AC}', FcColors.red),
  mentalHealth('Mental Health Moment', '\u{1F9D8}', FcColors.gold),
  coffeeBreak('Coffee Break', '☕', FcColors.mutedGold),
  other('Other', '⏰', FcColors.gray);

  const BreakCategory(this.wire, this.emoji, this.color);

  /// The persisted string, unchanged from the React payload.
  final String wire;
  final String emoji;
  final Color color;

  /// The label shown in the UI. Identical to [wire] today; separate so copy can
  /// change without a storage migration.
  String get label => wire;

  static BreakCategory fromWire(Object? value) {
    for (final BreakCategory category in BreakCategory.values) {
      if (category.wire == value) return category;
    }
    return BreakCategory.other;
  }
}
