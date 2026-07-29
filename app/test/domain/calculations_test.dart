import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/domain/calculations.dart';
import 'package:fuckcorpo/domain/models/break_category.dart';
import 'package:fuckcorpo/domain/models/break_record.dart';
import 'package:fuckcorpo/domain/models/salary.dart';

BreakRecord breakAt(DateTime when, {int durationMs = 60000, String id = 'x'}) =>
    BreakRecord(
      id: id,
      category: BreakCategory.bathroom,
      durationMs: durationMs,
      timestamp: when,
    );

void main() {
  group('salaryToPerMinute', () {
    // 8h/day x 5d/week x 52w/year x 60 = 124,800 working minutes.
    test('annual divides by 124,800 working minutes', () {
      expect(salaryToPerMinute(124800, SalaryType.annual), 1.0);
      expect(salaryToPerMinute(62400), closeTo(0.5, 1e-12));
    });

    test('hourly scales by 2,080 working hours', () {
      expect(salaryToPerMinute(60, SalaryType.hourly), closeTo(1.0, 1e-12));
    });

    test('monthly scales by 12', () {
      expect(
        salaryToPerMinute(10400, SalaryType.monthly),
        closeTo(124800 / 124800, 1e-12),
      );
    });

    test('weekly scales by 52', () {
      expect(salaryToPerMinute(2400, SalaryType.weekly), closeTo(1.0, 1e-12));
    });

    test('handles zero and negative amounts', () {
      expect(salaryToPerMinute(0), 0);
      expect(salaryToPerMinute(-124800), -1.0);
    });
  });

  group('calculateEarnings', () {
    test('converts milliseconds to minutes at the given rate', () {
      expect(calculateEarnings(60000, 1.0), closeTo(1.0, 1e-12));
      expect(calculateEarnings(30000, 2.0), closeTo(1.0, 1e-12));
      expect(calculateEarnings(0, 5.0), 0);
    });

    test('keeps sub-minute precision', () {
      expect(calculateEarnings(1500, 1.0), closeTo(0.025, 1e-12));
    });
  });

  group('date range selectors', () {
    final DateTime now = DateTime(2026, 3, 4, 13, 30); // Wednesday

    test('today includes midnight and excludes tomorrow', () {
      final List<BreakRecord> breaks = <BreakRecord>[
        breakAt(DateTime(2026, 3, 4), id: 'midnight'),
        breakAt(DateTime(2026, 3, 4, 23, 59, 59), id: 'late'),
        breakAt(DateTime(2026, 3, 3, 23, 59, 59), id: 'yesterday'),
        breakAt(DateTime(2026, 3, 5), id: 'tomorrow'),
      ];
      expect(
        todayBreaks(breaks, now: now).map((b) => b.id),
        <String>['midnight', 'late'],
      );
    });

    test('week starts on Sunday', () {
      // 2026-03-01 is a Sunday; 2026-02-28 is the Saturday before.
      final List<BreakRecord> breaks = <BreakRecord>[
        breakAt(DateTime(2026, 2, 28, 23), id: 'saturday'),
        breakAt(DateTime(2026, 3), id: 'sunday'),
        breakAt(DateTime(2026, 3, 7, 23), id: 'saturday-end'),
        breakAt(DateTime(2026, 3, 8), id: 'next-sunday'),
      ];
      expect(
        weekBreaks(breaks, now: now).map((b) => b.id),
        <String>['sunday', 'saturday-end'],
      );
    });

    test('week containing a Sunday "now" starts that same day', () {
      final List<BreakRecord> breaks = <BreakRecord>[
        breakAt(DateTime(2026, 3, 1, 0, 0, 1), id: 'sunday'),
        breakAt(DateTime(2026, 2, 28, 23), id: 'saturday'),
      ];
      expect(
        weekBreaks(breaks, now: DateTime(2026, 3, 1, 12)).map((b) => b.id),
        <String>['sunday'],
      );
    });

    test('month covers the first through the last instant', () {
      final List<BreakRecord> breaks = <BreakRecord>[
        breakAt(DateTime(2026, 2, 28, 23), id: 'feb'),
        breakAt(DateTime(2026, 3), id: 'first'),
        breakAt(DateTime(2026, 3, 31, 23, 59), id: 'last'),
        breakAt(DateTime(2026, 4), id: 'apr'),
      ];
      expect(
        monthBreaks(breaks, now: now).map((b) => b.id),
        <String>['first', 'last'],
      );
    });

    test('year covers Jan 1 through Dec 31', () {
      final List<BreakRecord> breaks = <BreakRecord>[
        breakAt(DateTime(2025, 12, 31, 23, 59), id: 'prev'),
        breakAt(DateTime(2026), id: 'jan1'),
        breakAt(DateTime(2026, 12, 31, 23, 59), id: 'dec31'),
        breakAt(DateTime(2027), id: 'next'),
      ];
      expect(
        yearBreaks(breaks, now: now).map((b) => b.id),
        <String>['jan1', 'dec31'],
      );
    });
  });

  group('totals', () {
    test('are zero for an empty list', () {
      expect(totalDuration(const <BreakRecord>[]), 0);
      expect(totalEarnings(const <BreakRecord>[], 1.0), 0);
    });

    test('sum a single break', () {
      final List<BreakRecord> breaks = <BreakRecord>[
        breakAt(DateTime(2026, 3, 4), durationMs: 120000),
      ];
      expect(totalDuration(breaks), 120000);
      expect(totalEarnings(breaks, 1.5), closeTo(3.0, 1e-12));
    });

    test('sum many breaks', () {
      final List<BreakRecord> breaks = <BreakRecord>[
        breakAt(DateTime(2026, 3, 4), durationMs: 60000, id: 'a'),
        breakAt(DateTime(2026, 3, 4), durationMs: 30000, id: 'b'),
        breakAt(DateTime(2026, 3, 4), durationMs: 90000, id: 'c'),
      ];
      expect(totalDuration(breaks), 180000);
      expect(totalEarnings(breaks, 2.0), closeTo(6.0, 1e-12));
    });
  });

  group('timeAgo', () {
    final DateTime now = DateTime(2026, 3, 4, 12);

    test('renders the React strings at each boundary', () {
      expect(timeAgo(now, now: now), 'just now');
      expect(
        timeAgo(now.subtract(const Duration(seconds: 59)), now: now),
        'just now',
      );
      expect(timeAgo(now.subtract(const Duration(minutes: 1)), now: now), '1m ago');
      expect(
        timeAgo(now.subtract(const Duration(minutes: 59)), now: now),
        '59m ago',
      );
      expect(timeAgo(now.subtract(const Duration(hours: 1)), now: now), '1h ago');
      expect(
        timeAgo(now.subtract(const Duration(hours: 23)), now: now),
        '23h ago',
      );
      expect(timeAgo(now.subtract(const Duration(days: 1)), now: now), '1d ago');
      expect(timeAgo(now.subtract(const Duration(days: 30)), now: now), '30d ago');
    });
  });
}
