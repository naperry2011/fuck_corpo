import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/data/app_repository.dart';
import 'package:fuckcorpo/domain/models/app_state.dart';
import 'package:fuckcorpo/domain/models/break_category.dart';
import 'package:fuckcorpo/domain/models/salary.dart';
import 'package:fuckcorpo/state/providers.dart';
import 'package:fuckcorpo/state/timer_controller.dart';

import '../helpers/fake_clock.dart';
import '../helpers/memory_store.dart';
import '../helpers/test_container.dart';

/// 124,800 annual is exactly 1.00 per working minute, which keeps the earnings
/// assertions readable.
const Salary _onePerMinute = Salary(
  amount: 124800,
  type: SalaryType.annual,
  currency: 'USD',
);

void main() {
  late MemoryStore store;
  late FakeClock clock;

  setUp(() {
    store = MemoryStore();
    clock = FakeClock(DateTime(2026, 7, 28, 10));
  });

  group('T2 start and stop', () {
    test('start records the category and a wall-clock start time', () {
      final container = makeTestContainer(store: store, clock: clock);
      final TimerController timer = container.read(timerControllerProvider);

      timer.start(BreakCategory.coffeeBreak);

      final AppState state = container.read(appControllerProvider);
      expect(state.runningTimer, isNotNull);
      expect(state.runningTimer!.category, BreakCategory.coffeeBreak);
      expect(state.runningTimer!.startedAt, clock.now);
      expect(timer.isRunning, isTrue);
    });

    test('elapsed comes from the wall clock, not a tick counter', () {
      final container = makeTestContainer(store: store, clock: clock);
      final TimerController timer = container.read(timerControllerProvider);

      timer.start(BreakCategory.bathroom);
      clock.advance(const Duration(minutes: 3, seconds: 20));

      expect(timer.elapsed(), const Duration(minutes: 3, seconds: 20));
    });

    test('stop logs a break with the elapsed duration and earnings', () {
      final container = makeTestContainer(store: store, clock: clock);
      container.read(appControllerProvider.notifier).setSalary(_onePerMinute);
      final TimerController timer = container.read(timerControllerProvider);

      timer.start(BreakCategory.smokeBreak);
      clock.advance(const Duration(minutes: 5));
      final TimerStopResult result = timer.stop();

      expect(result.logged, isTrue);
      expect(result.elapsed, const Duration(minutes: 5));
      expect(result.earnings, closeTo(5, 0.0001));

      final AppState state = container.read(appControllerProvider);
      expect(state.runningTimer, isNull);
      expect(state.breaks, hasLength(1));
      expect(state.breaks.single.category, BreakCategory.smokeBreak);
      expect(state.breaks.single.durationMs, 300000);
      expect(state.breaks.single.timestamp, clock.now);
    });

    test('a sub-second break is discarded, not logged', () {
      final container = makeTestContainer(store: store, clock: clock);
      final TimerController timer = container.read(timerControllerProvider);

      timer.start(BreakCategory.bathroom);
      clock.advance(const Duration(milliseconds: 600));
      final TimerStopResult result = timer.stop();

      expect(result.logged, isFalse);
      expect(result.discarded, isTrue);
      expect(result.elapsed, const Duration(milliseconds: 600));
      expect(container.read(appControllerProvider).breaks, isEmpty);
      expect(container.read(appControllerProvider).runningTimer, isNull);
    });

    test('exactly one second is still too short, matching React', () {
      final container = makeTestContainer(store: store, clock: clock);
      final TimerController timer = container.read(timerControllerProvider);

      timer.start(BreakCategory.bathroom);
      clock.advance(const Duration(milliseconds: 1000));

      expect(timer.stop().logged, isFalse);
    });

    test('stop with no running timer is a no-op', () {
      final container = makeTestContainer(store: store, clock: clock);
      final TimerController timer = container.read(timerControllerProvider);

      final TimerStopResult result = timer.stop();

      expect(result.logged, isFalse);
      expect(result.discarded, isFalse);
      expect(result.wasRunning, isFalse);
      expect(container.read(appControllerProvider).breaks, isEmpty);
    });
  });

  group('T6 the running timer survives a reload', () {
    test('the running timer is persisted on start', () {
      final container = makeTestContainer(store: store, clock: clock);
      container.read(timerControllerProvider).start(BreakCategory.other);

      final Map<String, dynamic> raw =
          jsonDecode(store.read(AppRepository.storageKey)!)
              as Map<String, dynamic>;
      expect(raw['runningTimer'], isNotNull);
      expect(
        (raw['runningTimer'] as Map<String, dynamic>)['category'],
        'Other',
      );
    });

    test('a fresh container rehydrates elapsed time from the wall clock', () {
      final container = ProviderContainer(
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          clockProvider.overrideWithValue(clock.call),
        ],
      );
      container.read(timerControllerProvider).start(BreakCategory.bathroom);
      container.dispose();

      clock.advance(const Duration(minutes: 12));
      // Same store, new container: this is what a reload looks like.
      final reloaded = makeTestContainer(store: store, clock: clock);
      final TimerController timer = reloaded.read(timerControllerProvider);

      expect(timer.isRunning, isTrue);
      expect(timer.elapsed(), const Duration(minutes: 12));
    });
  });
}
