import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/domain/models/break_category.dart';
import 'package:fuckcorpo/domain/models/break_record.dart';
import 'package:fuckcorpo/features/dashboard/dashboard_metrics.dart';

final DateTime _now = DateTime(2026, 7, 28, 14, 30);

BreakRecord _record({
  required String id,
  required DateTime timestamp,
  int durationMs = 10 * 60000,
  BreakCategory category = BreakCategory.bathroom,
}) => BreakRecord(
  id: id,
  category: category,
  durationMs: durationMs,
  timestamp: timestamp,
);

void main() {
  group('D6 seven-day earnings series', () {
    test('always has 7 points ending today, oldest first', () {
      final List<DailyEarnings> series = dailyEarningsSeries(
        const <BreakRecord>[],
        1,
        now: _now,
      );

      expect(series.length, 7);
      expect(series.first.day, DateTime(2026, 7, 22));
      expect(series.last.day, DateTime(2026, 7, 28));
      expect(series.every((DailyEarnings d) => d.amount == 0), isTrue);
    });

    test('labels match the React weekday/month/day format', () {
      final List<DailyEarnings> series = dailyEarningsSeries(
        const <BreakRecord>[],
        1,
        now: _now,
      );

      expect(series.last.label, 'Tue, Jul 28');
      expect(series.first.label, 'Wed, Jul 22');
    });

    test('buckets earnings into the right day and rounds to cents', () {
      // 10 minutes at 1.005/min lands on 10.05.
      final List<DailyEarnings> series = dailyEarningsSeries(
        <BreakRecord>[
          _record(id: 'a', timestamp: DateTime(2026, 7, 28, 9)),
          _record(id: 'b', timestamp: DateTime(2026, 7, 26, 9)),
          // Outside the window entirely.
          _record(id: 'c', timestamp: DateTime(2026, 7, 1, 9)),
        ],
        1.005,
        now: _now,
      );

      expect(series.last.amount, closeTo(10.05, 0.0001));
      expect(series[4].amount, closeTo(10.05, 0.0001));
      expect(series[3].amount, 0);
    });
  });

  group('D7 hourly break patterns', () {
    test('produces 24 buckets keyed by local hour', () {
      final List<int> counts = hourlyBreakCounts(<BreakRecord>[
        _record(id: 'a', timestamp: DateTime(2026, 7, 28, 0, 5)),
        _record(id: 'b', timestamp: DateTime(2026, 7, 27, 10, 30)),
        _record(id: 'c', timestamp: DateTime(2026, 7, 26, 10, 59)),
        _record(id: 'd', timestamp: DateTime(2026, 7, 26, 23, 1)),
      ]);

      expect(counts.length, 24);
      expect(counts[0], 1);
      expect(counts[10], 2);
      expect(counts[23], 1);
      expect(counts[11], 0);
    });

    test('hour labels use the 12-hour AM/PM form', () {
      expect(hourLabel(0), '12AM');
      expect(hourLabel(1), '1AM');
      expect(hourLabel(11), '11AM');
      expect(hourLabel(12), '12PM');
      expect(hourLabel(13), '1PM');
      expect(hourLabel(23), '11PM');
    });
  });

  group('D8 category breakdown', () {
    test('counts per category and drops the empty ones', () {
      final Map<BreakCategory, int> counts = categoryCounts(<BreakRecord>[
        _record(id: 'a', timestamp: _now),
        _record(id: 'b', timestamp: _now),
        _record(
          id: 'c',
          timestamp: _now,
          category: BreakCategory.coffeeBreak,
        ),
      ]);

      expect(counts[BreakCategory.bathroom], 2);
      expect(counts[BreakCategory.coffeeBreak], 1);
      expect(counts.containsKey(BreakCategory.smokeBreak), isFalse);
    });

    test('every present category keeps its own color', () {
      final Map<BreakCategory, int> counts = categoryCounts(<BreakRecord>[
        for (final BreakCategory c in BreakCategory.values)
          _record(id: c.name, timestamp: _now, category: c),
      ]);

      expect(counts.length, BreakCategory.values.length);
      expect(
        counts.keys.map((BreakCategory c) => c.color).toSet().length,
        BreakCategory.values.length,
      );
    });
  });

  group('D9 performance metrics', () {
    test('is null when there is nothing logged', () {
      expect(performanceMetrics(const <BreakRecord>[]), isNull);
    });

    test('average, longest, count and most common category', () {
      final PerformanceMetrics metrics = performanceMetrics(<BreakRecord>[
        _record(id: 'a', timestamp: _now, durationMs: 60000),
        _record(id: 'b', timestamp: _now, durationMs: 180000),
        _record(
          id: 'c',
          timestamp: _now,
          durationMs: 120000,
          category: BreakCategory.smokeBreak,
        ),
      ])!;

      expect(metrics.totalBreaks, 3);
      expect(metrics.avgDurationMs, closeTo(120000, 0.0001));
      expect(metrics.longestBreakMs, 180000);
      expect(metrics.mostCommonCategory, BreakCategory.bathroom);
    });

    test('ties resolve to the first category in enum order', () {
      final PerformanceMetrics metrics = performanceMetrics(<BreakRecord>[
        _record(id: 'a', timestamp: _now, category: BreakCategory.other),
        _record(id: 'b', timestamp: _now, category: BreakCategory.bathroom),
      ])!;

      expect(metrics.mostCommonCategory, BreakCategory.bathroom);
    });
  });

  group('D5 employee number', () {
    test('is the break count plus 1000, padded to five digits', () {
      expect(employeeNumber(0), '01000');
      expect(employeeNumber(7), '01007');
      expect(employeeNumber(9000), '10000');
    });
  });
}
