import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/calculations.dart';
import '../domain/models/break_category.dart';
import '../domain/models/break_record.dart';
import '../domain/models/running_timer.dart';
import 'app_controller.dart';
import 'providers.dart';

/// What happened when the user pressed STOP.
///
/// React discarded a sub-second break silently; here the caller is told, so it
/// can say so out loud (deviation D-105).
class TimerStopResult {
  const TimerStopResult({
    required this.wasRunning,
    required this.logged,
    required this.elapsed,
    required this.earnings,
  });

  static const TimerStopResult notRunning = TimerStopResult(
    wasRunning: false,
    logged: false,
    elapsed: Duration.zero,
    earnings: 0,
  );

  final bool wasRunning;
  final bool logged;
  final Duration elapsed;
  final double earnings;

  /// Ran, but was too short to keep.
  bool get discarded => wasRunning && !logged;
}

/// Live-timer logic. Holds no clock of its own: the running timer lives in
/// persisted [AppState], and elapsed time is always `now - startedAt`, which is
/// what makes the timer survive navigation and reload (BUG-008).
class TimerController {
  TimerController(this._ref);

  /// React discarded anything at or below one second (`elapsed > 1000`).
  static const Duration minimumBreak = Duration(seconds: 1);

  final Ref _ref;

  AppController get _app => _ref.read(appControllerProvider.notifier);

  DateTime get _now => _ref.read(clockProvider)();

  RunningTimer? get running => _ref.read(appControllerProvider).runningTimer;

  bool get isRunning => running != null;

  BreakCategory? get category => running?.category;

  Duration elapsed() {
    final RunningTimer? timer = running;
    if (timer == null) return Duration.zero;
    final Duration value = timer.elapsed(now: _now);
    // A clock that moved backwards must not render a negative break.
    return value.isNegative ? Duration.zero : value;
  }

  void start(BreakCategory category) {
    if (isRunning) return;
    _app.startRunningTimer(
      RunningTimer(startedAt: _now, category: category),
    );
  }

  TimerStopResult stop() {
    final RunningTimer? timer = running;
    if (timer == null) return TimerStopResult.notRunning;

    final Duration value = elapsed();
    _app.clearRunningTimer();

    if (value <= minimumBreak) {
      return TimerStopResult(
        wasRunning: true,
        logged: false,
        elapsed: value,
        earnings: 0,
      );
    }

    final double rate = _ref.read(perMinuteRateProvider);
    _app.addBreak(
      BreakRecord(
        id: const Uuid().v4(),
        category: timer.category,
        durationMs: value.inMilliseconds,
        timestamp: _now,
      ),
    );
    return TimerStopResult(
      wasRunning: true,
      logged: true,
      elapsed: value,
      earnings: calculateEarnings(value.inMilliseconds, rate),
    );
  }
}

final Provider<TimerController> timerControllerProvider =
    Provider<TimerController>(TimerController.new);
