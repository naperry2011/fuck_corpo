import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/app_settings.dart';
import '../domain/models/app_state.dart';
import '../domain/models/break_record.dart';
import '../domain/models/running_timer.dart';
import '../domain/models/salary.dart';
import 'providers.dart';

/// Single source of truth for persisted state. Port of the `useReducer` store
/// in `src/context/AppContext.jsx`: every mutation writes through to storage,
/// which is what the React `useEffect` did on each state change.
class AppController extends Notifier<AppState> {
  @override
  AppState build() => ref.read(appRepositoryProvider).load();

  void _commit(AppState next) {
    state = next;
    // Fire and forget, matching the React persist-on-change behavior. The
    // in-memory state is authoritative for the current frame.
    ref.read(appRepositoryProvider).save(next);
  }

  void setSalary(Salary salary) => _commit(state.copyWith(salary: salary));

  void addBreak(BreakRecord record) =>
      _commit(state.copyWith(breaks: <BreakRecord>[...state.breaks, record]));

  void deleteBreak(String id) => _commit(
    state.copyWith(
      breaks: state.breaks.where((BreakRecord b) => b.id != id).toList(),
    ),
  );

  void updateSettings(AppSettings settings) =>
      _commit(state.copyWith(settings: settings));

  void addAchievement(String id) {
    if (state.achievements.contains(id)) return;
    _commit(
      state.copyWith(achievements: <String>[...state.achievements, id]),
    );
  }

  void setOnboarded({required bool onboarded}) =>
      _commit(state.copyWith(onboarded: onboarded));

  void startRunningTimer(RunningTimer timer) =>
      _commit(state.copyWith(runningTimer: timer));

  void clearRunningTimer() =>
      _commit(state.copyWith(clearRunningTimer: true));

  /// Replaces everything with a validated imported payload.
  void replaceState(AppState next) => _commit(next);

  /// Back to defaults, without a page reload (BUG-006).
  void reset() {
    state = AppState.initial;
    ref.read(appRepositoryProvider).clear();
  }
}
