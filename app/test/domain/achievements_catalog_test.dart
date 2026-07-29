import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/domain/achievements_catalog.dart';
import 'package:fuckcorpo/domain/models/break_category.dart';
import 'package:fuckcorpo/domain/models/break_record.dart';

BreakRecord rec({
  String id = 'x',
  int durationMs = 60000,
  DateTime? at,
}) => BreakRecord(
  id: id,
  category: BreakCategory.bathroom,
  durationMs: durationMs,
  timestamp: at ?? DateTime(2026, 3, 4, 12),
);

List<BreakRecord> many(int n) =>
    List<BreakRecord>.generate(n, (i) => rec(id: 'b$i'));

Achievement byId(String id) =>
    achievementsCatalog.firstWhere((a) => a.id == id);

bool unlocked(String id, List<BreakRecord> breaks, double earned) =>
    byId(id).isUnlocked(breaks, earned);

void main() {
  test('catalog has the 11 React badges in order with unique ids', () {
    expect(
      achievementsCatalog.map((a) => a.id).toList(),
      <String>[
        'first_flush',
        'regular',
        'consistency',
        'century',
        'hundred_club',
        'thousand_club',
        'ten_k_club',
        'marathon',
        'quick_draw',
        'early_bird',
        'night_owl',
      ],
    );
    expect(
      achievementsCatalog.map((a) => a.id).toSet(),
      hasLength(achievementsCatalog.length),
    );
    for (final Achievement a in achievementsCatalog) {
      expect(a.name, isNotEmpty);
      expect(a.description, isNotEmpty);
      expect(a.icon, isNotEmpty);
    }
  });

  group('count-based badges unlock at their boundary', () {
    test('first_flush at 1 break', () {
      expect(unlocked('first_flush', many(0), 0), isFalse);
      expect(unlocked('first_flush', many(1), 0), isTrue);
    });

    test('regular at 10 breaks', () {
      expect(unlocked('regular', many(9), 0), isFalse);
      expect(unlocked('regular', many(10), 0), isTrue);
    });

    test('consistency at 50 breaks', () {
      expect(unlocked('consistency', many(49), 0), isFalse);
      expect(unlocked('consistency', many(50), 0), isTrue);
    });

    test('century at 100 breaks', () {
      expect(unlocked('century', many(99), 0), isFalse);
      expect(unlocked('century', many(100), 0), isTrue);
    });
  });

  group('earnings badges unlock at their boundary', () {
    test('hundred_club at 100', () {
      expect(unlocked('hundred_club', many(1), 99.99), isFalse);
      expect(unlocked('hundred_club', many(1), 100), isTrue);
    });

    test('thousand_club at 1000', () {
      expect(unlocked('thousand_club', many(1), 999.99), isFalse);
      expect(unlocked('thousand_club', many(1), 1000), isTrue);
    });

    test('ten_k_club at 10000', () {
      expect(unlocked('ten_k_club', many(1), 9999.99), isFalse);
      expect(unlocked('ten_k_club', many(1), 10000), isTrue);
    });
  });

  group('session-shape badges', () {
    test('marathon needs a single session of 30 minutes or more', () {
      expect(
        unlocked('marathon', <BreakRecord>[rec(durationMs: 30 * 60000 - 1)], 0),
        isFalse,
      );
      expect(
        unlocked('marathon', <BreakRecord>[rec(durationMs: 30 * 60000)], 0),
        isTrue,
      );
    });

    test('quick_draw needs a session above zero and at most 2 minutes', () {
      expect(unlocked('quick_draw', <BreakRecord>[rec(durationMs: 0)], 0), isFalse);
      expect(unlocked('quick_draw', <BreakRecord>[rec(durationMs: 1)], 0), isTrue);
      expect(
        unlocked('quick_draw', <BreakRecord>[rec(durationMs: 2 * 60000)], 0),
        isTrue,
      );
      expect(
        unlocked('quick_draw', <BreakRecord>[rec(durationMs: 2 * 60000 + 1)], 0),
        isFalse,
      );
    });
  });

  group('time-of-day badges use local hours', () {
    test('early_bird needs a break before 9 AM', () {
      expect(
        unlocked('early_bird', <BreakRecord>[rec(at: DateTime(2026, 3, 4, 9))], 0),
        isFalse,
      );
      expect(
        unlocked(
          'early_bird',
          <BreakRecord>[rec(at: DateTime(2026, 3, 4, 8, 59))],
          0,
        ),
        isTrue,
      );
    });

    test('night_owl needs a break at or after 6 PM', () {
      expect(
        unlocked(
          'night_owl',
          <BreakRecord>[rec(at: DateTime(2026, 3, 4, 17, 59))],
          0,
        ),
        isFalse,
      );
      expect(
        unlocked('night_owl', <BreakRecord>[rec(at: DateTime(2026, 3, 4, 18))], 0),
        isTrue,
      );
    });
  });

  test('newlyUnlocked returns only badges not already held', () {
    final List<String> unlockedIds = newlyUnlocked(
      breaks: many(10),
      lifetimeEarned: 0,
      alreadyUnlocked: const <String>['first_flush'],
    );
    expect(unlockedIds, <String>['regular', 'quick_draw']);
  });
}
