import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../domain/calculations.dart';
import '../../domain/models/break_category.dart';
import '../../domain/models/break_record.dart';

/// One point on the EARNINGS OVER TIME series.
@immutable
class DailyEarnings {
  const DailyEarnings({
    required this.day,
    required this.label,
    required this.amount,
  });

  /// Local midnight for this bucket.
  final DateTime day;

  /// `Tue, Jul 28`, matching the React `toLocaleDateString` options.
  final String label;
  final double amount;
}

final DateFormat _dayLabel = DateFormat('EEE, MMM d', 'en_US');

/// The last seven days of earnings, oldest first, ending on today.
List<DailyEarnings> dailyEarningsSeries(
  List<BreakRecord> breaks,
  double perMinuteRate, {
  DateTime? now,
}) {
  final DateTime ref = now ?? DateTime.now();
  final DateTime today = DateTime(ref.year, ref.month, ref.day);
  return <DailyEarnings>[
    for (int back = 6; back >= 0; back--)
      () {
        final DateTime start = today.subtract(Duration(days: back));
        final DateTime end = start.add(const Duration(days: 1));
        final double amount = totalEarnings(
          breaksInRange(breaks, start, end),
          perMinuteRate,
        );
        return DailyEarnings(
          day: start,
          label: _dayLabel.format(start),
          // React charted `parseFloat(value.toFixed(2))`.
          amount: double.parse(amount.toStringAsFixed(2)),
        );
      }(),
  ];
}

/// Break counts per local hour of day, always 24 entries.
List<int> hourlyBreakCounts(List<BreakRecord> breaks) {
  final List<int> counts = List<int>.filled(24, 0);
  for (final BreakRecord b in breaks) {
    counts[b.timestamp.hour]++;
  }
  return counts;
}

/// `12AM`, `1AM`, ... `11PM`.
String hourLabel(int hour) {
  final String suffix = hour >= 12 ? 'PM' : 'AM';
  final int display = hour % 12 == 0 ? 12 : hour % 12;
  return '$display$suffix';
}

/// Counts per category, in enum order, omitting categories with no breaks.
Map<BreakCategory, int> categoryCounts(List<BreakRecord> breaks) {
  final Map<BreakCategory, int> counts = <BreakCategory, int>{};
  for (final BreakCategory category in BreakCategory.values) {
    final int count = breaks
        .where((BreakRecord b) => b.category == category)
        .length;
    if (count > 0) counts[category] = count;
  }
  return counts;
}

/// The four PERFORMANCE METRICS figures.
@immutable
class PerformanceMetrics {
  const PerformanceMetrics({
    required this.avgDurationMs,
    required this.longestBreakMs,
    required this.totalBreaks,
    required this.mostCommonCategory,
  });

  final double avgDurationMs;
  final int longestBreakMs;
  final int totalBreaks;
  final BreakCategory mostCommonCategory;
}

/// Null when nothing has been logged, mirroring the React `funStats` guard.
PerformanceMetrics? performanceMetrics(List<BreakRecord> breaks) {
  if (breaks.isEmpty) return null;
  final Map<BreakCategory, int> counts = categoryCounts(breaks);
  // Ties resolve to the earlier category in enum order, since `counts` is
  // built in that order and a strict `>` never displaces the incumbent.
  BreakCategory top = counts.keys.first;
  for (final MapEntry<BreakCategory, int> entry in counts.entries) {
    if (entry.value > counts[top]!) top = entry.key;
  }
  return PerformanceMetrics(
    avgDurationMs: totalDuration(breaks) / breaks.length,
    longestBreakMs: breaks
        .map((BreakRecord b) => b.durationMs)
        .reduce((int a, int b) => a > b ? a : b),
    totalBreaks: breaks.length,
    mostCommonCategory: top,
  );
}

/// The memo addressee: break count plus 1000, padded to five digits.
String employeeNumber(int breakCount) =>
    (breakCount + 1000).toString().padLeft(5, '0');
