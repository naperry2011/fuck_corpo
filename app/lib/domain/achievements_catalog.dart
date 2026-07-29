import 'package:flutter/foundation.dart';

import 'models/break_record.dart';

/// Signature of an unlock predicate: the full break history plus lifetime
/// earnings.
typedef AchievementCheck =
    bool Function(List<BreakRecord> breaks, double lifetimeEarned);

/// One badge. Ported from `ACHIEVEMENTS` in `src/pages/Achievements.jsx`.
@immutable
class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.check,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementCheck check;

  bool isUnlocked(List<BreakRecord> breaks, double lifetimeEarned) =>
      check(breaks, lifetimeEarned);
}

const int _minute = 60000;

final List<Achievement> achievementsCatalog = <Achievement>[
  Achievement(
    id: 'first_flush',
    name: 'First Flush',
    description: 'Log your first break',
    icon: '\u{1F6BD}',
    check: (breaks, _) => breaks.isNotEmpty,
  ),
  Achievement(
    id: 'regular',
    name: 'The Regular',
    description: 'Log 10 breaks',
    icon: '\u{1F4CA}',
    check: (breaks, _) => breaks.length >= 10,
  ),
  Achievement(
    id: 'consistency',
    name: 'Consistency Champion',
    description: 'Log 50 breaks',
    icon: '\u{1F3C6}',
    check: (breaks, _) => breaks.length >= 50,
  ),
  Achievement(
    id: 'century',
    name: 'Century',
    description: 'Log 100 breaks',
    icon: '\u{1F4AF}',
    check: (breaks, _) => breaks.length >= 100,
  ),
  Achievement(
    id: 'hundred_club',
    name: r'$100 Club',
    description: r'Earn $100 lifetime',
    icon: '\u{1F4B5}',
    check: (_, earned) => earned >= 100,
  ),
  Achievement(
    id: 'thousand_club',
    name: r'$1,000 Club',
    description: r'Earn $1,000 lifetime',
    icon: '\u{1F4B0}',
    check: (_, earned) => earned >= 1000,
  ),
  Achievement(
    id: 'ten_k_club',
    name: r'$10,000 Club',
    description: r'Earn $10,000 lifetime',
    icon: '\u{1F3E6}',
    check: (_, earned) => earned >= 10000,
  ),
  Achievement(
    id: 'marathon',
    name: 'Marathon Runner',
    description: 'Single session over 30 min',
    icon: '\u{1F3C3}',
    check: (breaks, _) => breaks.any((b) => b.durationMs >= 30 * _minute),
  ),
  Achievement(
    id: 'quick_draw',
    name: 'Quick Draw',
    description: 'Session under 2 minutes',
    icon: '⚡',
    check: (breaks, _) =>
        breaks.any((b) => b.durationMs > 0 && b.durationMs <= 2 * _minute),
  ),
  Achievement(
    id: 'early_bird',
    name: 'Early Bird',
    description: 'Break before 9 AM',
    icon: '\u{1F305}',
    check: (breaks, _) => breaks.any((b) => b.timestamp.hour < 9),
  ),
  Achievement(
    id: 'night_owl',
    name: 'Night Owl',
    description: 'Break after 6 PM',
    icon: '\u{1F989}',
    check: (breaks, _) => breaks.any((b) => b.timestamp.hour >= 18),
  ),
];

/// Badge ids that are now satisfied but not yet held. Evaluating this in the
/// domain layer, rather than in the screen, is what keeps the unlock toast from
/// firing on every rebuild.
List<String> newlyUnlocked({
  required List<BreakRecord> breaks,
  required double lifetimeEarned,
  required List<String> alreadyUnlocked,
}) => <String>[
  for (final Achievement a in achievementsCatalog)
    if (!alreadyUnlocked.contains(a.id) && a.isUnlocked(breaks, lifetimeEarned))
      a.id,
];
