import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/data/app_repository.dart';
import 'package:fuckcorpo/domain/models/app_settings.dart';
import 'package:fuckcorpo/domain/models/app_state.dart';
import 'package:fuckcorpo/domain/models/break_category.dart';
import 'package:fuckcorpo/domain/models/break_record.dart';
import 'package:fuckcorpo/domain/models/running_timer.dart';
import 'package:fuckcorpo/domain/models/salary.dart';
import 'package:fuckcorpo/features/timer/timer_screen.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/memory_store.dart';
import '../../helpers/pump_app.dart';

/// 124,800 annual is exactly 1.00 per working minute.
const Salary _onePerMinute = Salary(
  amount: 124800,
  type: SalaryType.annual,
  currency: 'USD',
);

final DateTime _now = DateTime(2026, 7, 28, 10);

String _seed({
  List<BreakRecord> breaks = const <BreakRecord>[],
  RunningTimer? runningTimer,
}) {
  final AppState state = AppState(
    schemaVersion: AppState.currentSchemaVersion,
    salary: _onePerMinute,
    breaks: breaks,
    settings: AppSettings.initial,
    achievements: const <String>[],
    onboarded: true,
    runningTimer: runningTimer,
  );
  return jsonEncode(state.toJson());
}

MemoryStore _storeWith({
  List<BreakRecord> breaks = const <BreakRecord>[],
  RunningTimer? runningTimer,
}) => MemoryStore(<String, String>{
  AppRepository.storageKey: _seed(
    breaks: breaks,
    runningTimer: runningTimer,
  ),
});

BreakRecord _record({
  required String id,
  required Duration duration,
  required DateTime timestamp,
  BreakCategory category = BreakCategory.bathroom,
}) => BreakRecord(
  id: id,
  category: category,
  durationMs: duration.inMilliseconds,
  timestamp: timestamp,
);

String _textOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

void main() {
  late MemoryStore store;
  late FakeClock clock;

  setUp(() {
    store = _storeWith();
    clock = FakeClock(_now);
  });

  group('T1 live timer', () {
    testWidgets('renders the five category chips', (tester) async {
      await pumpFcScreen(
        tester,
        const TimerScreen(),
        store: store,
        clock: clock,
      );

      for (final BreakCategory category in BreakCategory.values) {
        expect(
          find.byKey(TimerScreen.categoryChipKey(category)),
          findsOneWidget,
          reason: 'missing chip for ${category.label}',
        );
        expect(find.text(category.label), findsWidgets);
      }
    });

    testWidgets('shows a zeroed clock and earnings before starting', (
      tester,
    ) async {
      await pumpFcScreen(
        tester,
        const TimerScreen(),
        store: store,
        clock: clock,
      );

      expect(_textOf(tester, TimerScreen.clockKey), '00:00');
      expect(_textOf(tester, TimerScreen.earningsKey), r'$0.00');
      expect(find.text('START BREAK'), findsOneWidget);
    });

    testWidgets('the clock and earnings advance while running', (tester) async {
      await pumpFcScreen(
        tester,
        const TimerScreen(),
        store: store,
        clock: clock,
      );

      await tester.tap(find.text('START BREAK'));
      await tester.pump();
      expect(find.text('STOP & LOG'), findsOneWidget);

      clock.advance(const Duration(minutes: 2, seconds: 30));
      await tester.pump(TimerScreen.tickInterval);

      expect(_textOf(tester, TimerScreen.clockKey), '02:30');
      expect(_textOf(tester, TimerScreen.earningsKey), r'$2.50');
    });

    testWidgets('status and motivation copy appear only while running', (
      tester,
    ) async {
      await pumpFcScreen(
        tester,
        const TimerScreen(),
        store: store,
        clock: clock,
      );

      expect(find.text('Earning since you stepped away...'), findsNothing);

      await tester.tap(find.text('START BREAK'));
      await tester.pump();

      expect(find.text('Earning since you stepped away...'), findsOneWidget);
      expect(find.byKey(TimerScreen.motivationKey), findsOneWidget);
      expect(_textOf(tester, TimerScreen.motivationKey), isNotEmpty);
    });

    testWidgets('category chips are inert while the timer runs', (
      tester,
    ) async {
      await pumpFcScreen(
        tester,
        const TimerScreen(),
        store: store,
        clock: clock,
      );

      await tester.tap(
        find.byKey(TimerScreen.categoryChipKey(BreakCategory.coffeeBreak)),
      );
      await tester.pump();
      await tester.tap(find.text('START BREAK'));
      await tester.pump();

      // Tapping a different chip mid-break must not change the category.
      await tester.tap(
        find.byKey(TimerScreen.categoryChipKey(BreakCategory.smokeBreak)),
      );
      await tester.pump();

      clock.advance(const Duration(minutes: 4));
      await tester.tap(find.text('STOP & LOG'));
      await tester.pump();

      final AppState saved = AppState.fromJson(
        jsonDecode(store.read(AppRepository.storageKey)!),
      );
      expect(saved.breaks.single.category, BreakCategory.coffeeBreak);
    });
  });

  group('T2 stop and log', () {
    testWidgets('stopping logs the break and toasts the earnings', (
      tester,
    ) async {
      await pumpFcScreen(
        tester,
        const TimerScreen(),
        store: store,
        clock: clock,
      );

      await tester.tap(find.text('START BREAK'));
      await tester.pump();
      clock.advance(const Duration(minutes: 7));
      await tester.tap(find.text('STOP & LOG'));
      await tester.pump();

      expect(find.text(r'Break logged! You earned $7.00'), findsOneWidget);
      expect(find.text('START BREAK'), findsOneWidget);
      expect(_textOf(tester, TimerScreen.clockKey), '00:00');
    });

    testWidgets('a sub-second break is discarded with an explicit notice', (
      tester,
    ) async {
      await pumpFcScreen(
        tester,
        const TimerScreen(),
        store: store,
        clock: clock,
      );

      await tester.tap(find.text('START BREAK'));
      await tester.pump();
      clock.advance(const Duration(milliseconds: 400));
      await tester.tap(find.text('STOP & LOG'));
      await tester.pump();

      expect(find.text(TimerScreen.discardedMessage), findsOneWidget);
      final AppState saved = AppState.fromJson(
        jsonDecode(store.read(AppRepository.storageKey)!),
      );
      expect(saved.breaks, isEmpty);
    });
  });

  group('T3 quick log', () {
    testWidgets('logs the entered minutes at noon local time', (tester) async {
      await pumpFcScreen(
        tester,
        const TimerScreen(),
        store: store,
        clock: clock,
      );

      await tester.enterText(find.byKey(TimerScreen.quickMinutesKey), '15');
      await tester.tap(find.text('Log Break'));
      await tester.pump();

      final AppState saved = AppState.fromJson(
        jsonDecode(store.read(AppRepository.storageKey)!),
      );
      expect(saved.breaks, hasLength(1));
      expect(saved.breaks.single.durationMs, 15 * 60000);
      expect(saved.breaks.single.category, BreakCategory.bathroom);
      expect(
        saved.breaks.single.timestamp,
        DateTime(_now.year, _now.month, _now.day, 12),
      );
      expect(find.text(r'Break logged! You earned $15.00'), findsOneWidget);
      // The field resets after a successful log, as it does in React.
      expect(
        tester.widget<TextField>(find.byKey(TimerScreen.quickMinutesKey))
            .controller!
            .text,
        isEmpty,
      );
    });

    testWidgets('rejects a value outside 1 to 480 minutes', (tester) async {
      await pumpFcScreen(
        tester,
        const TimerScreen(),
        store: store,
        clock: clock,
      );

      await tester.enterText(find.byKey(TimerScreen.quickMinutesKey), '600');
      await tester.tap(find.text('Log Break'));
      await tester.pump();

      expect(find.text(TimerScreen.invalidMinutesMessage), findsOneWidget);
      final AppState saved = AppState.fromJson(
        jsonDecode(store.read(AppRepository.storageKey)!),
      );
      expect(saved.breaks, isEmpty);
    });

    testWidgets('rejects an empty or zero value', (tester) async {
      await pumpFcScreen(
        tester,
        const TimerScreen(),
        store: store,
        clock: clock,
      );

      await tester.tap(find.text('Log Break'));
      await tester.pump();
      expect(find.text(TimerScreen.invalidMinutesMessage), findsOneWidget);

      await tester.enterText(find.byKey(TimerScreen.quickMinutesKey), '0');
      await tester.tap(find.text('Log Break'));
      await tester.pump();

      final AppState saved = AppState.fromJson(
        jsonDecode(store.read(AppRepository.storageKey)!),
      );
      expect(saved.breaks, isEmpty);
    });
  });

  group('T4 today summary', () {
    testWidgets('counts only today, with duration and earnings', (
      tester,
    ) async {
      final MemoryStore seeded = _storeWith(
        breaks: <BreakRecord>[
          _record(
            id: 'a',
            duration: const Duration(minutes: 10),
            timestamp: DateTime(2026, 7, 28, 9),
          ),
          _record(
            id: 'b',
            duration: const Duration(minutes: 5),
            timestamp: DateTime(2026, 7, 28, 9, 30),
          ),
          // Yesterday: must not count.
          _record(
            id: 'c',
            duration: const Duration(minutes: 45),
            timestamp: DateTime(2026, 7, 27, 9),
          ),
        ],
      );

      await pumpFcScreen(
        tester,
        const TimerScreen(),
        store: seeded,
        clock: clock,
      );

      expect(_textOf(tester, TimerScreen.summaryCountKey), '2');
      expect(_textOf(tester, TimerScreen.summaryDurationKey), '15:00');
      expect(_textOf(tester, TimerScreen.summaryEarningsKey), r'$15.00');
    });
  });

  group('T5 recent breaks', () {
    testWidgets('shows the newest ten, newest first', (tester) async {
      final MemoryStore seeded = _storeWith(
        breaks: <BreakRecord>[
          for (int i = 0; i < 11; i++)
            _record(
              id: 'break-$i',
              duration: const Duration(minutes: 1),
              timestamp: DateTime(2026, 7, 28, 9).add(Duration(minutes: i)),
            ),
        ],
      );

      await pumpFcScreen(
        tester,
        const TimerScreen(),
        store: seeded,
        clock: clock,
      );

      expect(
        find.byKey(const ValueKey<String>('break_item_break-10')),
        findsOneWidget,
      );
      // The oldest of the eleven falls off the list.
      expect(
        find.byKey(const ValueKey<String>('break_item_break-0')),
        findsNothing,
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('break_item_'),
        ),
        findsNWidgets(10),
      );
    });

    testWidgets('renders emoji, category, timeAgo, duration and earnings', (
      tester,
    ) async {
      final MemoryStore seeded = _storeWith(
        breaks: <BreakRecord>[
          _record(
            id: 'one',
            category: BreakCategory.mentalHealth,
            duration: const Duration(minutes: 12),
            timestamp: DateTime(2026, 7, 28, 8),
          ),
        ],
      );

      await pumpFcScreen(
        tester,
        const TimerScreen(),
        store: seeded,
        clock: clock,
      );

      Finder inItem(Finder matching) => find.descendant(
        of: find.byKey(const ValueKey<String>('break_item_one')),
        matching: matching,
      );

      expect(inItem(find.text(BreakCategory.mentalHealth.emoji)),
          findsOneWidget);
      expect(inItem(find.text('Mental Health Moment')), findsOneWidget);
      expect(inItem(find.text('2h ago')), findsOneWidget);
      expect(inItem(find.text('12:00')), findsOneWidget);
      expect(inItem(find.text(r'$12.00')), findsOneWidget);
    });

    testWidgets('deleting a break removes it and toasts', (tester) async {
      final MemoryStore seeded = _storeWith(
        breaks: <BreakRecord>[
          _record(
            id: 'one',
            duration: const Duration(minutes: 3),
            timestamp: DateTime(2026, 7, 28, 8),
          ),
        ],
      );

      await pumpFcScreen(
        tester,
        const TimerScreen(),
        store: seeded,
        clock: clock,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('break_delete_one')),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('break_item_one')),
        findsNothing,
      );
      expect(find.text('Break deleted'), findsOneWidget);
      final AppState saved = AppState.fromJson(
        jsonDecode(seeded.read(AppRepository.storageKey)!),
      );
      expect(saved.breaks, isEmpty);
    });

    testWidgets('the section is hidden when there are no breaks', (
      tester,
    ) async {
      await pumpFcScreen(
        tester,
        const TimerScreen(),
        store: store,
        clock: clock,
      );

      expect(find.text('Recent Breaks'), findsNothing);
    });
  });

  group('T6 a running timer survives a reload', () {
    testWidgets('mounts already running with the elapsed time restored', (
      tester,
    ) async {
      final MemoryStore seeded = _storeWith(
        runningTimer: RunningTimer(
          startedAt: _now.subtract(const Duration(minutes: 8)),
          category: BreakCategory.smokeBreak,
        ),
      );

      await pumpFcScreen(
        tester,
        const TimerScreen(),
        store: seeded,
        clock: clock,
      );

      expect(find.text('STOP & LOG'), findsOneWidget);
      expect(_textOf(tester, TimerScreen.clockKey), '08:00');
      expect(_textOf(tester, TimerScreen.earningsKey), r'$8.00');
    });
  });
}
