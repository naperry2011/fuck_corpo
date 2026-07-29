import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/data/app_repository.dart';
import 'package:fuckcorpo/domain/achievements_catalog.dart';
import 'package:fuckcorpo/domain/models/app_settings.dart';
import 'package:fuckcorpo/domain/models/app_state.dart';
import 'package:fuckcorpo/domain/models/break_category.dart';
import 'package:fuckcorpo/domain/models/break_record.dart';
import 'package:fuckcorpo/domain/models/salary.dart';
import 'package:fuckcorpo/features/achievements/achievements_screen.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/memory_store.dart';
import '../../helpers/pump_app.dart';

final DateTime _now = DateTime(2026, 7, 28, 14, 30);

const Salary _salary = Salary(
  amount: 124800,
  type: SalaryType.annual,
  currency: 'USD',
);

/// 100 minutes of breaks at 1.00 per minute: exactly $100.00 lifetime.
final List<BreakRecord> _breaks = <BreakRecord>[
  BreakRecord(
    id: 'a',
    category: BreakCategory.bathroom,
    durationMs: 10 * 60000,
    timestamp: DateTime(2026, 7, 28, 9),
  ),
  BreakRecord(
    id: 'b',
    category: BreakCategory.coffeeBreak,
    durationMs: 20 * 60000,
    timestamp: DateTime(2026, 7, 26, 9),
  ),
  BreakRecord(
    id: 'c',
    category: BreakCategory.smokeBreak,
    durationMs: 30 * 60000,
    timestamp: DateTime(2026, 7, 5, 9),
  ),
  BreakRecord(
    id: 'd',
    category: BreakCategory.bathroom,
    durationMs: 40 * 60000,
    timestamp: DateTime(2026, 2, 10, 19),
  ),
];

MemoryStore _store({
  List<BreakRecord> breaks = const <BreakRecord>[],
  List<String> achievements = const <String>[],
}) => MemoryStore(<String, String>{
  AppRepository.storageKey: jsonEncode(
    AppState(
      schemaVersion: AppState.currentSchemaVersion,
      salary: _salary,
      breaks: breaks,
      settings: AppSettings.initial,
      achievements: achievements,
      onboarded: true,
    ).toJson(),
  ),
});

List<String> _persistedAchievements(MemoryStore store) =>
    AppState.fromJson(
      jsonDecode(store.data[AppRepository.storageKey]!),
    ).achievements;

Future<void> _pump(WidgetTester tester, MemoryStore store) async {
  await pumpFcScreen(
    tester,
    const AchievementsScreen(),
    store: store,
    clock: FakeClock(_now),
    surfaceSize: const Size(1100, 6000),
  );
  // The unlock sweep runs after the first frame.
  await tester.pump();
}

String _textAt(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

void main() {
  group('A1 badge grid', () {
    testWidgets('renders all 11 badges with the unlocked count', (
      tester,
    ) async {
      await _pump(tester, _store(breaks: _breaks));

      expect(achievementsCatalog.length, 11);
      for (final Achievement a in achievementsCatalog) {
        expect(
          find.byKey(AchievementsScreen.badgeKey(a.id)),
          findsOneWidget,
          reason: 'badge ${a.id} is missing',
        );
        expect(find.text(a.name), findsOneWidget);
        expect(find.text(a.description), findsOneWidget);
      }

      expect(find.text('INVESTOR ACHIEVEMENTS'), findsOneWidget);
      expect(
        find.text('Your portfolio of bathroom accomplishments'),
        findsOneWidget,
      );
      // first_flush, hundred_club, marathon and night_owl are satisfied.
      expect(_textAt(tester, AchievementsScreen.progressKey), '4 / 11 unlocked');
    });

    testWidgets('locked badges show the lock, unlocked show the icon', (
      tester,
    ) async {
      await _pump(tester, _store(breaks: _breaks));

      expect(find.text('UNLOCKED'), findsNWidgets(4));
      expect(find.text('LOCKED'), findsNWidgets(7));
      expect(
        _textAt(tester, AchievementsScreen.badgeIconKey('first_flush')),
        '\u{1F6BD}',
      );
      expect(
        _textAt(tester, AchievementsScreen.badgeIconKey('century')),
        '\u{1F512}',
      );
    });

    testWidgets('with no breaks nothing is unlocked', (tester) async {
      await _pump(tester, _store());

      expect(_textAt(tester, AchievementsScreen.progressKey), '0 / 11 unlocked');
      expect(find.text('LOCKED'), findsNWidgets(11));
    });
  });

  group('A2 unlock persistence', () {
    testWidgets('newly satisfied badges are written through the controller', (
      tester,
    ) async {
      final MemoryStore store = _store(breaks: _breaks);
      await _pump(tester, store);

      expect(
        _persistedAchievements(store),
        containsAll(<String>[
          'first_flush',
          'hundred_club',
          'marathon',
          'night_owl',
        ]),
      );
      expect(_persistedAchievements(store).length, 4);
    });

    testWidgets('a toast fires once per newly unlocked badge', (tester) async {
      await _pump(tester, _store(breaks: _breaks));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Achievement Unlocked: First Flush!'),
        findsOneWidget,
      );

      // Rebuilding must not re-announce anything.
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.text('Achievement Unlocked: First Flush!'),
        findsOneWidget,
      );
    });

    testWidgets('already held badges are not re-announced', (tester) async {
      await _pump(
        tester,
        _store(
          breaks: _breaks,
          achievements: const <String>[
            'first_flush',
            'hundred_club',
            'marathon',
            'night_owl',
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Achievement Unlocked:'), findsNothing);
      expect(_textAt(tester, AchievementsScreen.progressKey), '4 / 11 unlocked');
    });
  });

  group('A3 earnings statement', () {
    testWidgets('reports lifetime, sessions, average and top category', (
      tester,
    ) async {
      await _pump(tester, _store(breaks: _breaks));

      expect(find.text('OFFICIAL EARNINGS STATEMENT'), findsOneWidget);
      expect(find.text('FuckCorpo Inc.'), findsOneWidget);
      expect(find.text('July 28, 2026'), findsOneWidget);
      expect(_textAt(tester, AchievementsScreen.lifetimeKey), r'$100.00');
      expect(_textAt(tester, AchievementsScreen.sessionsKey), '4');
      expect(_textAt(tester, AchievementsScreen.avgDurationKey), '25:00');
      expect(
        _textAt(tester, AchievementsScreen.topCategoryKey),
        'Bathroom',
      );
      expect(find.textContaining('BOARD OF DIRECTORS'), findsOneWidget);
    });

    testWidgets('copying writes the ASCII payload and flips the label', (
      tester,
    ) async {
      final List<MethodCall> calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await _pump(tester, _store(breaks: _breaks));

      await tester.tap(find.text('Copy to Clipboard'));
      await tester.pump();
      await tester.pump();

      expect(calls, hasLength(1));
      final String payload = calls.single.arguments['text'] as String;
      expect(payload, contains('OFFICIAL EARNINGS STATEMENT'));
      expect(payload, contains(r'Lifetime Earnings: $100.00'));
      expect(payload, contains('Achievements Unlocked: 4/11'));
      expect(payload, contains('   Date: July 28, 2026'));

      expect(find.text('Copied!'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.text('Copy to Clipboard'), findsOneWidget);
    });
  });

  group('A4 CEO comparison', () {
    testWidgets('shows both figures, the multiplier and the footnote', (
      tester,
    ) async {
      await _pump(tester, _store(breaks: _breaks));

      expect(find.text('EXECUTIVE COMPARISON REPORT'), findsOneWidget);
      expect(find.text('Bathroom break earnings analysis'), findsOneWidget);
      expect(find.text('While you earned'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
      expect(_textAt(tester, AchievementsScreen.ceoYouKey), r'$100.00');
      // 100 minutes at 83.33 per minute.
      expect(_textAt(tester, AchievementsScreen.ceoThemKey), r'$8,333.00');
      expect(_textAt(tester, AchievementsScreen.ceoMultiplierKey), '83x');
      expect(
        find.textContaining(r'~$5,000/hour'),
        findsOneWidget,
      );
    });

    testWidgets('with no earnings the multiplier is suppressed', (
      tester,
    ) async {
      await _pump(tester, _store());

      expect(find.text('EXECUTIVE COMPARISON REPORT'), findsOneWidget);
      expect(find.byKey(AchievementsScreen.ceoMultiplierKey), findsNothing);
    });
  });
}
