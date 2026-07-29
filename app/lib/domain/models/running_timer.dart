import 'package:flutter/foundation.dart';

import 'break_category.dart';

/// A timer that is currently counting. Persisting this is what lets the timer
/// survive navigation and reload (BUG-008); elapsed time is always derived from
/// the wall clock, never from a tick counter.
@immutable
class RunningTimer {
  const RunningTimer({required this.startedAt, required this.category});

  final DateTime startedAt;
  final BreakCategory category;

  Duration elapsed({DateTime? now}) =>
      (now ?? DateTime.now()).difference(startedAt);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'startedAt': startedAt.toIso8601String(),
    'category': category.wire,
  };

  static RunningTimer? fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? startedAt = json['startedAt'];
    if (startedAt is! String) return null;
    final DateTime? parsed = DateTime.tryParse(startedAt);
    if (parsed == null) return null;
    return RunningTimer(
      startedAt: parsed,
      category: BreakCategory.fromWire(json['category']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RunningTimer &&
      other.startedAt == startedAt &&
      other.category == category;

  @override
  int get hashCode => Object.hash(startedAt, category);
}
